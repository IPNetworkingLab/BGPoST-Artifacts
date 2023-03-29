use core::hash::Hash;
use std::{collections::HashMap, fs, path::Path};
use toml;
use serde::Serialize;

use serde_json::{Result, Value, json};

use structopt::StructOpt;

mod dijkstra;
mod ntf_parser;
mod ofiber;

trait DAG<T: Ord + Hash> {
    fn get(&self) -> HashMap<T, Vec<T>>;
    fn parents_to_childs(&self) -> HashMap<usize, Vec<usize>>;
    fn bfs(&self, root: &usize) -> Vec<usize>;
    fn long_loops(&self, root: &usize) -> Option<Vec<u32>>;
    fn routes(&self, root: &usize) -> HashMap<usize, Vec<Vec<usize>>>;
}

impl DAG<usize> for HashMap<&usize, Vec<&usize>> {

    fn get(&self) -> HashMap<usize, Vec<usize>> {
        let mut hash: HashMap<usize, Vec<usize>> = HashMap::new();
        for (node, successors) in self {
            hash.insert(**node, successors.iter().map(|succ| **succ).collect());
        }
        hash
    }

    fn parents_to_childs(&self) -> HashMap<usize, Vec<usize>> {
        let mut hash: HashMap<usize, Vec<usize>> = HashMap::new();
        for (&node, parents) in self {
            for parent in parents {
                if parent != &node {
                    match hash.get_mut(parent) {
                        Some(x) => {x.push(*node);}
                        None => {hash.insert(**parent, vec![*node]);}
                    }
                }
            }
        }

        hash
    }

    fn bfs(&self, _root: &usize) -> Vec<usize> {
        vec![]
    }


    fn long_loops(&self, _root: &usize) -> Option<Vec<u32>> {
        None
    }


    fn routes(&self, root: &usize) -> HashMap<usize, Vec<Vec<usize>>> {
        HashMap::new()
    }

}

impl DAG<usize> for HashMap<usize, Vec<usize>> {

    fn get(&self) -> HashMap<usize, Vec<usize>> {
        let mut hash: HashMap<usize, Vec<usize>> = HashMap::new();
        for (node, successors) in self {
            hash.insert(*node, successors.iter().map(|succ| *succ).collect());
        }
        hash
    }

    fn parents_to_childs(&self) -> HashMap<usize, Vec<usize>> {
        let mut hash: HashMap<usize, Vec<usize>> = HashMap::new();
        for (&node, parents) in self {
            for parent in parents {
                if parent != &node {
                    match hash.get_mut(parent) {
                        Some(x) => {x.push(node);}
                        None => {hash.insert(*parent, vec![node]);}
                    }
                }
            }
        }

        hash
    }

    fn routes(&self, root: &usize) -> HashMap<usize, Vec<Vec<usize>>> {

        fn dfs(graph: &HashMap<usize, Vec<usize>>, node: &usize, route: &Vec<&usize>, collect: &mut HashMap<usize, Vec<Vec<usize>>>) {
            //println!("current node {}", node);
            if !graph.contains_key(node) {return;}
            for nexthop in &graph[node] {
                let current = [&route[..], &[nexthop]].concat();
                dfs(graph, nexthop, &current, collect);
                //println!("{:#?}", &current);
                let new = current.iter().map(|&x| *x).collect::<Vec<usize>>();

                match collect.get_mut(nexthop) {
                    Some(a) => { a.push(new) },
                    None => { let _  = collect.insert(*nexthop, vec![new]); }
                }
            }
        }


        let mut routes: HashMap<usize, Vec<Vec<usize>>> = HashMap::new();
        dfs(self, root, &vec![&root], &mut routes);

        routes
    }

    fn bfs(&self, root: &usize) -> Vec<usize> {
        fn level(graph: &HashMap<usize, Vec<usize>>, acc: &mut Vec<usize>, node: &usize) {
            println!("{}", node);
            //if acc.contains(node) { return }
            match graph.get(node) {
                Some(childs) => {
                    println!("{:#?}", childs);
                    //acc.append(&mut std::iter::once(node).chain(childs).map(|x| *x).collect());
                    acc.extend_from_slice(childs);
                    childs.iter().for_each(|child| level(graph, acc, child));
                },
                None => {}
            }
        }
        //let mut res: Vec<usize> = Vec::new();
        let mut res: Vec<usize> = vec![*root];
        level(self, &mut res, root);
        res
    }

    /// Search with a BFS for loops longer than 2-hops in the graph.
    /// Root is the starting point of the search.
    fn long_loops(&self, root: &usize) -> Option<Vec<u32>> {
        
        fn myloop(graph: &HashMap<usize, Vec<usize>>, explored: &mut Vec<usize>, path: &mut Vec<usize>, node: &usize) -> Option<(usize, Vec<usize>)> {
            // If node already explored, found a loop
            if path.contains(node) { 
                println!("Loop {} {:#?} {:#?}", node, path, explored);
                return Some((*node, path.clone())) 
            }

            // Else, continue to explore the graph
            explored.push(*node);
            path.push(*node);
            match graph.get(node) {
                // If current node is found in the graph 
                None => {path.pop();},
                Some(childs) => {
                    for child in childs {
                    // for each child of the current node
                    match myloop(graph, explored, path, &child) {
                        None => (),
                        Some(p) => return Some(p)
                    };
                }},
            }
            path.pop();
            None
        }

        println!("Loop graph {:#?}", self);
        let ret = myloop(self, &mut Vec::new(), &mut Vec::new(), root);
        let the_loop2: Option<Vec<u32>> = match ret {
            None => None,
            Some((node, a_loop)) => {
                println!("a_loop {:#?} {}", a_loop, node);
                let mut loop_iter = a_loop.iter();
                // consume iterator until the first node of the loop is reached
                loop_iter.any(|id| *id == node);
                // collect the remaining vector content as the loop hops
                let mut ret: Vec<u32> = loop_iter.map(|&id| id as u32).collect();
                // prefix the loop with the first node
                let mut a = vec![node as u32];
                a.append(&mut ret);
                Some(a)
            }
        };
        println!("the_loop {:#?}", the_loop2);
        the_loop2
    }
}

trait MyGraph<T: Ord + Hash>: dijkstra::Graph<T> {
    fn failed(&self, link: Option<(&T, &T)>) -> Self;
    fn revert(&self) -> Self;
    fn spdag<'a>(&'a self, root: &'a T) -> Option<HashMap<T, Vec<T>>>;
    //fn rspdag<'a>(&'a self, root: &'a T) -> Option<HashMap<&T, Vec<&T>>>;
}

impl MyGraph<usize> for Vec<Vec<(usize, i32)>> {

    fn failed(&self, link: Option<(&usize, &usize)>) -> Self {
        match link {
            None => self.clone(),
            Some((src, dst)) => {
                let mut ret: Vec<Vec<(usize, i32)>> = Vec::with_capacity(self.len());
                for (idx, successors) in self.iter().enumerate() {
                    if &idx == src || &idx == dst {
                        ret.push(successors.iter().filter_map(|(neigh, wheight)| if neigh != if &idx == src {dst} else {src} { Some((*neigh, *wheight)) } else { None }).collect());
                    } else {
                        ret.push(successors.clone());
                    }
                }
                ret
            }
        }
    }

    fn revert(&self) -> Self {
        let mut ret: Vec<Vec<(usize, i32)>> = Vec::with_capacity(self.len());
        for (src, successors) in self.iter().enumerate() {
            let mut line: Vec<(usize, i32)> = Vec::new();
            for (dst, _) in successors {
                self[*dst].iter().filter_map(|(child, cost)| if child == &src {Some((*dst, *cost))} else {None}).for_each(|x| line.push(x));
            }
            ret.push(line);
        }
        ret
    }
    
    fn spdag<'a>(&'a self, root: &'a usize) -> Option<HashMap<usize, Vec<usize>>> {
        match dijkstra::dijkstra(self, root) {
            None => None,
            Some(data) => Some(DAG::get(&data))
        }
    }
    
    /*fn rspdag<'a>(&'a self, root: &'a usize) -> Option<HashMap<&'a usize, Vec<&'a usize>>> {
        MyGraph::revert(self).spdag(root)
        //MyGraph::spdag(&MyGraph::revert(self), root)
    }*/
}

#[macro_export]
macro_rules! rspdag {
    ( $graph:expr,$root:expr ) => {
        {
            MyGraph::revert($graph).spdag($root)
        }
    }
}

fn merge_vectors(a: &Vec<usize>, b: &Vec<usize>) -> Vec<usize> {
    let mut res: Vec<usize> = Vec::new();
    let mut a = a.clone();
    let mut b = b.clone();
    a.sort();
    b.sort();

    let (mut it1, mut it2) = if a.len() < b.len() { (a.iter(), b.iter()) } else { (b.iter(), a.iter())};
    let mut x = it1.next();
    let mut y = it2.next();

    while x != None && y != None {
        let xi = x.unwrap();
        let yi = y.unwrap();
        //println!("xi {} yi {}", xi, yi);
        if xi < yi {
            res.push(*xi);
            x = it1.next();
        } else if xi > yi {
            res.push(*yi);
            y = it2.next();
        } else {
            res.push(*xi);
            x = it1.next();
            y = it2.next();
        }
    }
    //println!("res {:#?}", res);
    for i in if x == None { y.into_iter().chain(it2) } else { x.into_iter().chain(it1) } {
        res.push(*i);
    }
    //println!("res {:#?}", res);
    res
}

fn flop_one_way<'a>(successors: &Vec<Vec<(usize, i32)>>, (x, y): (usize, usize)) -> Option<HashMap<u32, Vec<Vec<u32>>>>{
    println!("FLOP for {} -> {}", x, y);
    let successors = &*successors;
    // TODO: check if real link

    // spt with x as root
    let spt = match MyGraph::spdag(successors, &x){
        Some(value) => value,
        None => panic!("Unable to build the initial spt")
    };
    println!("spdag(x) {:#?}", spt);
    
    // check if x -> y in spt
    // TODO: iter on y's successors, remove parent and BFS
    if !spt[&y].iter().any(|real_x| *real_x == x) {
        println!("Failed link unused. No loop possible.");
        return None
    }

    // get affected nodes
    let affected_nodes: Vec<usize> = spt.parents_to_childs().bfs(&y);
    println!("affected nodes {:#?}", affected_nodes);

    let mut loopy_dests: HashMap<u32, Vec<Vec<u32>>> = HashMap::new();

    let new_succ = MyGraph::failed(successors, Some((&x,&y)));
    println!("G' {:#?}", new_succ);
    let mut merged_rspt: HashMap<usize, Vec<usize>> = HashMap::new();
    for affected in affected_nodes {
        println!("Evaluating affected node {}", affected);
        // rspdag(G, d)
        let old_rspdag = match rspdag!(successors, &affected) {
            Some(data) => data,
            None => panic!("Empty rSPT before link failure")
        };
        println!("old rspdag {:#?}", old_rspdag);

        // rspdag(G', d)
        let new_rspdag = match rspdag!(&new_succ, &affected) {
            Some(data) => data,
            None => panic!("Empty rSPT before link failure")
        };
        println!("new_rspdag {:#?}", new_rspdag);

        // merge dags
        let mut loops: Vec<Vec<u32>> = Vec::new();
        for (node, old_parents) in old_rspdag {
            let new_parents = &new_rspdag[&node];
            merged_rspt.insert(node, merge_vectors(&old_parents, &new_parents));
            loops.append(
                &mut old_parents
                .iter()
                .filter_map(|x| if new_rspdag.contains_key(&x) && node != *x && new_rspdag[&x].contains(&node) {Some(vec![*x as u32, node as u32])} else {None})
                .collect::<Vec<Vec<u32>>>()
            );
        }

        println!("{} merged_rspdag {:#?}", loops.len() > 0, merged_rspt);

        if loops.len() > 0 {
            println!("loops {:#?}", loops);
            loopy_dests.insert(affected as u32, loops);
        } else {
            // detect longer cycle
            match merged_rspt.parents_to_childs().long_loops(&affected) {
                None => {},
                Some(a_loop) => {loopy_dests.insert(affected as u32, vec![a_loop]);}
            }
        }
        //loopy_dests.insert(affected as u32, if loops.len() > 0 {loops} else {merged_rspt.parents_to_childs().long_loops(&affected)});
    }

    println!("Loopy destinations with possible loops.\n{:#?}", loopy_dests);
    Some(loopy_dests)
}


fn flop<'a>(successors: &Vec<Vec<(usize, i32)>>, (x, y): (usize, usize)) -> Option<HashMap<u32, Vec<Vec<u32>>>> {
    let mut res: HashMap<u32, Vec<Vec<u32>>> = match flop_one_way(&successors, (x.clone(), y.clone())) {
        None => HashMap::new(),
        Some(loops) => loops
    };
    match flop_one_way(&successors, (y.clone(), x.clone())) {
        None => {},
        Some(a_loop) => for (key, value) in a_loop.iter() {
            if let Some(mut current) = res.get_mut(key) {
                println!("current {:#?}", current);
               // current.insert(value.clone());
            } else {
                res.insert(*key, value.clone());
            }
        }
    }
    println!("final {:#?}", res);
    if res.len() == 0 { None } else { Some(res) }
}

fn all_flops<'a>(successors: &Vec<Vec<(usize, i32)>>, dump: bool) {
    let mut todo: Vec<(usize, usize)> = Vec::new();
    for x in 0..successors.len() {
        for (y, _) in successors.get(x).unwrap() {
            if !todo.contains(&(*y,x)) {
                todo.push((x,*y));
                println!("{} {}", x, y);
            }
        }
    }

    let mut res: HashMap<String, HashMap<String, Vec<Vec<u32>>>> = HashMap::new();

    for (x,y) in todo.iter() {
        let tuple = (*x, *y);
        match flop(&successors, tuple) {
            None => {
                println!("No possible loop found.");
            },
            Some(result) => {res.insert(format!("{}_{}", *x, *y), result.iter().map(|(key, value)| (format!("{}", key), value.clone())).collect());}
        }
    }
    
    if dump {
        let serialized = toml::to_string(&res).unwrap();
        println!("{}", serialized);
        fs::write("loops.toml", serialized);
    }
}

#[derive(StructOpt, Clone)]
struct Cli {
    #[structopt(long)]
    dump: Option<bool>,
    #[structopt(short, long, default_value="1")]
    debug: u8,
    #[structopt(long)]
    path: String,
    #[structopt(long)]
    output: String
}

fn main() {
    let mut opt = Cli::from_args();
    let dump = match opt.dump { None => false, Some(value) => value};

    let path: &Path = opt.path.as_ref();
    println!("{}", opt.path);
    if !path.exists() {
        println!("Path <{}> not found.", opt.path);
        return;
    }
    if !path.is_file() {
        println!("Path <{}> is not a file.", opt.path);
        return;
    }

    let output: &Path = opt.output.as_ref();
    if output.exists() {
        println!("File <{}> exists! It will be overwritten.", opt.output);
    }

    let mut house: Vec<Vec<(usize, i32)>> = Vec::with_capacity(6);
    house.push(vec![(1, 1), (2, 10)]);
    house.push(vec![(0, 1), (2, 1), (3, 1), (4, 10)]);
    house.push(vec![(0, 10), (1, 1), (4, 1), (5, 1)]);
    house.push(vec![(1, 1), (5, 1)]);
    house.push(vec![(1, 10), (2, 1)]);
    house.push(vec![(2, 1), (3, 1)]);

    
        

    //MyGraph::revert(&house);
    //let n = MyGraph::spdag(&house, &5).unwrap();
    //let b = &n.parents_to_childs();
    //let c = &b.bfs(&2);
    //println!("spdag {:#?}\nchilds {:#?}\nbfs {:#?}", &n, b, c);
    //println!("{:#?}", rspdag!(&house, &1));

    /*for i in 0..6 {
        if i != 4 {
            let res = failed!(geant, Some((1,2)))(&i);
            match &i {
                0 => assert_eq!(res, [(1, 1), (2, 10)]),
                1 => assert_eq!(res, [(0, 1), (3, 1), (4, 10)]),
                2 => assert_eq!(res, [(0, 10), (4, 1), (5, 1)]),
                3 => assert_eq!(res, [(1, 1), (5, 1)]),
                5 => assert_eq!(res, [(2, 1), (3, 1)]),
                _ => {}
            }
        }
    }*/
    /*println!("{:#?}", geant(&4));
    println!("{:#?}", revert(&4, geant));
    println!("{:#?}", prelude::dijkstra_all(&4, geant));
    println!("{:#?}", prelude::dijkstra_all(&4, |&n| revert(&n, geant)));*/
    //println!("{:#?}", spt!(4, geant));
    //assert_eq!(prelude::build_path(&0, &spt!(4, failed!(geant, Some((1,2))))), [4, 2, 5, 3, 1, 0]);
    
    //flop(&house, (1, 2));
    //flop(&house, (0, 1));
    //flop(&house, (2, 1));
    //flop(&house, (1, 3));
    //flop(&house, (3, 1));
    //flop(&house, (5, 2));
    //flop(&house, (5, 1));
    //all_flops(&house, dump);
    //ntf_parser::parser("house.ntf".to_string());

    //println!("{:#?}", merge_vectors(&vec![2], &vec![3, 2]));
    /*let mut tmp: HashMap<usize, Vec<usize>> = HashMap::new();
    tmp.insert(0, vec![1]);
    tmp.insert(1, vec![2]);
    tmp.insert(2, vec![3, 4]);
    tmp.insert(4, vec![5]);
    tmp.insert(5, vec![1]);
    println!("{:#?}", tmp.long_loops(&0));
    tmp.remove_entry(&5);
    println!("{:#?}", tmp.long_loops(&0));*/

    //ofiber::myfun();

    let topo = ntf_parser::loader(opt.path);
    let successors = ofiber::topo_to_graph(&topo);
    let mut routes: HashMap<usize, HashMap<usize, Vec<Vec<usize>>>> = HashMap::new();

    for (head, tail) in topo.keys() {
        let heada = *head as usize;
        let taila = *tail as usize;
        if !routes.contains_key(&heada) {
            routes.insert(heada, get_routes(&successors, &heada));
        }

        if !routes.contains_key(&taila) {
            routes.insert(taila, get_routes(&successors, &taila));
        }
    }
    println!("{:#?}", routes);
    let j = json!(routes);
    println!(":{:#?}", j);
    fs::write(output, j.to_string());
}

pub fn get_routes(successors: &dyn dijkstra::Graph<usize>, root: &usize) -> HashMap<usize, Vec<Vec<usize>>> {
    let result = dijkstra::dijkstra(successors, root).unwrap();
    let reversed = result.parents_to_childs();
    reversed.routes(root)
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Setup {
        house: Vec<Vec<(usize, i32)>>,
        asymetric_house: Vec<Vec<(usize, i32)>>,
    }

    impl Setup {
        fn new() -> Self {
            let mut house: Vec<Vec<(usize, i32)>> = Vec::with_capacity(6);
            house.push(vec![(1, 1), (2, 10)]);
            house.push(vec![(0, 1), (2, 1), (3, 1), (4, 10)]);
            house.push(vec![(0, 10), (1, 1), (4, 1), (5, 1)]);
            house.push(vec![(1, 1), (5, 1)]);
            house.push(vec![(1, 10), (2, 1)]);
            house.push(vec![(2, 1), (3, 1)]);

            let mut ahouse: Vec<Vec<(usize, i32)>> = Vec::with_capacity(6);
            ahouse.push(vec![(1, 1), (2, 10)]);
            ahouse.push(vec![(0, 2), (2, 1), (3, 1), (4, 10)]);
            ahouse.push(vec![(0, 10), (1, 1), (4, 1), (5, 1)]);
            ahouse.push(vec![(1, 1), (5, 1)]);
            ahouse.push(vec![(1, 10), (2, 1)]);
            ahouse.push(vec![(2, 1), (3, 1)]);

            Self {
                house: house,
                asymetric_house: ahouse,
            }
        }
    }

    #[test]
    fn test_failed_none() {
        let setup = Setup::new();
        assert_eq!(MyGraph::failed(&setup.house, None), setup.house);
    }

    // TODO: explicit tests on all link failures

    #[test]
    fn test_failed_house_1_2() {
        let setup = Setup::new();
        assert_eq!(MyGraph::failed(&setup.house, Some((&1, &2))), vec![
            vec![(1, 1), (2, 10)],
            vec![(0, 1), (3, 1), (4, 10)],
            vec![(0, 10), (4, 1), (5, 1)],
            vec![(1, 1), (5, 1)],
            vec![(1, 10), (2, 1)],
            vec![(2, 1), (3, 1)]
        ]);
        assert_eq!(MyGraph::failed(&setup.house, Some((&2, &1))), vec![
            vec![(1, 1), (2, 10)],
            vec![(0, 1), (3, 1), (4, 10)],
            vec![(0, 10), (4, 1), (5, 1)],
            vec![(1, 1), (5, 1)],
            vec![(1, 10), (2, 1)],
            vec![(2, 1), (3, 1)]
        ]);
    }

    #[test]
    fn test_reverse_house() {
        let setup = Setup::new();
        assert_eq!(MyGraph::revert(&setup.house), setup.house);
    }

    #[test]
    fn test_reverse_asymetric_house() {
        let setup = Setup::new();
        assert_eq!(MyGraph::revert(&setup.asymetric_house), vec![
            vec![(1, 2), (2, 10)],
            vec![(0, 1), (2, 1), (3, 1), (4, 10)],
            vec![(0, 10), (1, 1), (4, 1), (5, 1)],
            vec![(1, 1), (5, 1)],
            vec![(1, 10), (2, 1)],
            vec![(2, 1), (3, 1)]
        ]);
    }

    #[test]
    fn test_spdag_house() {
        let setup = Setup::new();
        let house_spdag: HashMap<usize, Vec<usize>> = HashMap::new();
        /*house_spdag.insert(0, vec![])

        assert_eq!(MyGraph::spdag(&setup.house, 0), );*/
    }
}

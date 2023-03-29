use std::{collections::HashMap, fs::File, io::prelude::*};

//use cbor::Encoder;
use serde_cbor::to_vec;
use itertools::Itertools;

use crate::{ntf_parser, rspdag, MyGraph, DAG};
use crate::ntf_parser::Link;

fn insert(hash: &mut HashMap<usize, Vec<(usize, i32)>>, head: &u32, tail: &u32, links: &Vec<Link>, forward: bool) {
    match hash.get_mut(&(*head as usize)) {
        Some(vec) => {
            for link in links {
                let tuple = (*tail as usize, if forward {link.forward.unwrap()} else {link.reverse.unwrap()} as i32);
                vec.push(tuple);
            }
        },
        None => { 
            for link in links {
                let tuple = (*tail as usize, if forward {link.forward.unwrap()} else {link.reverse.unwrap()} as i32);
                hash.insert(*head as usize, vec![tuple]); 
            }
        }
    }
}

pub fn topo_to_graph(topo: &HashMap<(u32, u32), Vec<Link>>) -> Vec<Vec<(usize, i32)>> {
    let mut ret: Vec<Vec<(usize, i32)>> = Vec::new();
    let mut tmp: HashMap<usize, Vec<(usize, i32)>> = HashMap::new();
    for ((head, tail), links) in topo {
        insert(&mut tmp, head, tail, links, true);
        insert(&mut tmp, tail, head, links, false);
        println!("{} -> {}: {:#?}", head, tail, links);
    }
    for id in tmp.keys().sorted() {
        ret.push(tmp[id].to_vec());
    }
    ret
}

pub fn myfun () {
    fn bfs(dag: HashMap<usize, Vec<usize>>, root: &usize) -> (HashMap<usize, Vec<usize>>, Vec<usize>) {
        fn level(graph: &HashMap<usize, Vec<usize>>, acc: &mut HashMap<usize, Vec<usize>>, explored: &mut Vec<usize>, node: &usize) {
            //println!("{}", node);
            match graph.get(node) {
                Some(childs) => {
                    //println!("{:#?}", childs);
                    acc.insert(*node, childs.clone());
                    childs.iter().for_each(|child| level(graph, acc, explored, child));
                },
                None => {}
            }
            if !explored.contains(node) {
                explored.push(*node);
            }
        }
        let mut res: HashMap<usize, Vec<usize>> = HashMap::new();
        let mut explored: Vec<usize> = Vec::new();
        level(&dag, &mut res, &mut explored, root);
        (res, explored)
    }

    fn parse(successors: &Vec<Vec<(usize, i32)>>,
             data: &mut HashMap<usize, HashMap<usize, HashMap<&str, HashMap<usize, Vec<usize>>>>>,
             head: &usize,
             tail: &usize) 
        //-> (HashMap<usize, Vec<usize>>, HashMap<usize, Vec<usize>>) 
    {
        let dag = rspdag!(successors, head).unwrap();
        let (wls, explored) = bfs(dag.parents_to_childs(), tail);

        let mut parents: HashMap<usize, Vec<usize>> = HashMap::new();
        for node in &explored {
            match dag.get(&node) {
                Some(p) => {
                    if p.len() > 1 {
                        let mut explored_parent: Vec<usize> = Vec::new();
                        for i in p {
                            if explored.contains(i) {
                                explored_parent.push(*i);
                            }
                        }
                        if explored_parent.len() > 1 {
                            parents.insert(*node, explored_parent);
                        }
                    }
                },
                None => {}
            }
        }
        //println!("wls {:#?}\nparents {:#?}", wls, parents);

        let mut tmp: HashMap<&str, HashMap<usize, Vec<usize>>> = HashMap::new();
        if wls.len() > 0 {
            tmp.insert("wls", wls);
        }
        if parents.len() > 0 {
            tmp.insert("parents", parents);
        }
        let mut tmp3: HashMap<usize, Vec<usize>> = HashMap::new();
        let mut bitstring: u64 = 0;
        for i in &explored {
            bitstring |= 1 << i;
        }
        println!("{}", format!("{:x}", bitstring));

        tmp3.insert(0, vec![0, bitstring as usize]);
        tmp.insert("bs", tmp3);

        match data.get_mut(&(*tail as usize)) {
            Some(x) => {
                x.insert(*head as usize, tmp);
            },
            None => {
                let mut tmp2: HashMap<usize, HashMap<&str, HashMap<usize, Vec<usize>>>> = HashMap::new();
                tmp2.insert(*head as usize, tmp);
                data.insert(*tail as usize, tmp2);
            }
        }

        //(wls, parents)
    }

    let topo = ntf_parser::parser("house.ntf".to_string());
    let successors = topo_to_graph(&topo);
    let mut data: HashMap<usize, HashMap<usize, HashMap<&str, HashMap<usize, Vec<usize>>>>> = HashMap::new();
    for (head, tail) in topo.keys() {
        //if (head != &0 || tail != &1) && (head != &1 || tail != &0) { continue; }

        println!("{} <-> {}", head, tail);
        // tail view
        println!("{}", tail);
        parse(&successors, &mut data, &(*head as usize), &(*tail as usize));

        // head view
        println!("{}", head);
        parse(&successors, &mut data, &(*tail as usize), &(*head as usize));
        //break;
    }
    println!("{:#?}", data);

    for node in data.keys() {
        let encoded = to_vec(&data[node]).unwrap();
        let mut file = File::create(format!("node{}.cfg.cbor", node)).expect("Failed to create cbor output");
        file.write_all(encoded.as_slice());
    }
}

use std::{fs, collections::HashMap};

#[derive(Debug)]
pub struct Link {
    pub head: u32,
    pub tail: u32,
    pub forward: Option<u32>,
    pub reverse: Option<u32>,
    pub delay: u32,
    pub start: Option<u32>,
    pub end: Option<u32>
}

trait NTF {
    //fn node_id(nodes: &mut Vec<String>, node: String) -> u32;
}

impl NTF for HashMap<(u32, u32), Vec<Link>> {
    
}

fn node_id(nodes: &mut Vec<String>, node: String) -> u32 {
    if !nodes.contains(&node) {
        let before = nodes.len();
        nodes.push(node.clone());
        before as u32
    } else {
        nodes.iter().position(|x| *x == node).unwrap() as u32
    }
}

pub fn get_graph() {

}

fn string_to_u32(entry: &str) -> u32{
    return entry.to_string().parse::<u32>().unwrap();
}

pub fn loader(filename: String) -> HashMap<(u32, u32), Vec<Link>> {
    let mut links: HashMap<(u32, u32), Vec<Link>> = HashMap::new();

    let content = String::from_utf8(fs::read(filename).expect("Failed to open the NTF file")).expect("Failed to parse the file content");
    for line in content.split('\n') {
        let line_content = line.split(',').collect::<Vec<&str>>();
        if line_content.len() < 4 { continue; };
        let (head, tail, forward, reverse, delay, start, end) = match &line_content[..] {
            &[a, b, c, d, e] => (string_to_u32(a), string_to_u32(b), c.to_string().parse::<u32>().unwrap(), d.to_string().parse::<u32>().unwrap(), e.to_string().parse::<u32>().unwrap(), None, None),
            _ => unreachable!("{}", line)
        };

        let link = Link {
            head: head,
            tail: tail,
            forward: Some(forward),
            reverse: Some(reverse),
            delay: delay,
            start: start,
            end: end
        };

        let key = (head, tail);
        
        if let Some(existing_links_vec) = links.get_mut(&key) {
            existing_links_vec.push(link);
        } else {
            links.insert(key, vec![link]);
        }
    }

    println!("{:#?}", links);

    links
}

pub fn parser(filename: String) -> HashMap<(u32, u32), Vec<Link>> {
    let content = String::from_utf8(fs::read(filename).expect("Failed to open the NTF file")).expect("Failed to parse the file content");

    let mut nodes: Vec<String> = Vec::new();
    let mut links: HashMap<(u32, u32), Vec<Link>> = HashMap::new();
    let mut count = 0;
    let mut new_link = 0;

    for line in content.split('\n').filter(|line| line.len() > 4) {
        if line.get(0..1).unwrap() == "#" { continue; } // Got a comment
        count+=1;
        let line_content = line.split(' ').collect::<Vec<&str>>();
        let (head, tail, weight, delay, start, end) = match &line_content[..] {
            &[a, b, c, d] => (a.to_string(), b.to_string(), c.to_string().parse::<u32>().unwrap(), d.to_string().parse::<u32>().unwrap(), 0, 0),
            _ => unreachable!("{}", line)
        };

        let head_id = node_id(&mut nodes, head);
        let tail_id = node_id(&mut nodes, tail);
        println!("{} {} {}", line, head_id, tail_id);

        if let Some(existing_links_vec) = links.get(&(head_id, tail_id)) {
            println!("if1");
            let mut existing_links = existing_links_vec.iter();
            if existing_links.by_ref().any(|link| link.forward.is_some() && link.reverse.is_some() && (link.forward.unwrap() == weight || link.reverse.unwrap() == weight)) {
                // A link between head_id and tail_id already exists, we have a redudant link
            } else if existing_links.by_ref().any(|link| link.forward.is_some() && link.reverse.is_none()) {
                println!("Case 1");
            } else if existing_links.by_ref().any(|link| link.forward.is_none() && link.reverse.is_some()) {
                println!("Case 2");
            }
        } else if let Some(existing_links) = links.get_mut(&(tail_id, head_id)) {
            if let Some(pos) = existing_links.iter().position(|link| link.forward.is_some() && link.reverse.is_some() && (link.forward.unwrap() == weight || link.reverse.unwrap() == weight)) {
                // A link between head_id and tail_id already exists, we have a redudant link
                println!("{}", pos);
            } else if let Some(pos) = existing_links.iter().position(|link| link.forward.is_some() && link.reverse.is_none()) {
                let link = existing_links.get_mut(pos).unwrap();
                link.reverse = Some(weight);
            } else if let Some(pos) = existing_links.iter().position(|link| link.forward.is_none() && link.reverse.is_some()) {
                let link = existing_links.get_mut(pos).unwrap();
                link.forward = Some(weight);
            }
        } else {
            let link = Link {
                head: head_id,
                tail: tail_id,
                forward: Some(weight),
                reverse: None,
                delay: delay,
                start: None,
                end: None
            };
            links.insert((head_id, tail_id), vec![link]);
            new_link+=1;
        }
    }
    println!("{:#?}\n{:#?}\n{} {} {}", nodes, links, count, new_link, links.len());
    links
}

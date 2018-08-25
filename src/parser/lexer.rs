use super::ast::*;

pub struct Lexer<'a> {
    input: &'a str,
    pos: SourceLoc,
}


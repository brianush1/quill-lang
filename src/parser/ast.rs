pub struct Span {
    line: usize,
    column: usize,
    line_start: usize,
}

pub struct Token<'a> {
    ttype: TokenType,
    text: &'a [u8],
}
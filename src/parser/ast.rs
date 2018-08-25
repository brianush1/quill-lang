use std::collections::LinkedList as List;

pub type Expr<'a> = (ExprType<'a>, SourceLoc);
pub type Token<'a> = (TokenType<'a>, SourceLoc);
pub type SourceLoc = (usize, usize, usize);

pub enum TokenType<'a> {
    Int(usize),
    Float(f64),
    Kw(Keyword),
    Op(Operator),
    Id(&'a [u8]),
    Str(&'a [u8]),
    LParen, RParen,
    LBrace, RBrace,
    LCurly, RCurly,
    Dot, Comma, Colon,
}

pub enum Keyword {
    Const, Func, Local,
    Do, Enf, If, Elseif, Else,
    New, Class, Using, Namespace, In,
    For, While, Break, Continue, Return,
}

pub enum Operator {
    Add, Sub, Div, Mul, Mod, Set,
    Shr, Shl, Xor, Bor, Bnot, Band,
    Equ, Neq, Lt, Lte, Gt, Gte, And, Or
}

pub enum ExprType<'a> {
    EInt(usize),
    EFloat(f64),
    EId(&'a [u8]),
    EStr(&'a [u8]),
    EArray(List<Expr<'a>>),
    EBlock(List<Expr<'a>>),
    EMap(List<(Expr<'a>, Expr<'a>)>), // List<(key, value)>
    EClass(Box<Expr<'a>>, List<Expr<'a>>), // (name, List<Func/Var>)
    EIf(List<(Option<Expr<'a>>, Expr<'a>)>), // List<(cond, body)>
    EVar(bool, Box<Expr<'a>>, Box<Expr<'a>>), // (const, name, value)
    EFunc(bool, &'a [u8], List<Expr<'a>>, Box<Expr<'a>>), // (const, name, args, body)
}
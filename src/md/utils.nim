import parseutils



type
  TokenKind* {.pure.} = enum
    h1, h2, h3, h4, h5, h6 # title
    ol, ul, li # list
    paragraph, pre # code block
    em # *italic* => <em>italic</em>
    strong # **bold** => <strong>bold</strong>
    code # `monospace` => 
    a # [title](link) => <a href=link>title</a>
    strike # <strike>strikethrough</strike>
    img # <p><img alt="Image" title="icon" src="Icon-pictures.png" /></p>
    blockquote # <blockquote><p>Markdown uses email-style &gt; characters for blockquoting.</p></blockquote>
    hr # --- => </hr>
    br # </br>
  tk = TokenKind
  Token* = object
    case kind: TokenKind
    of tk.h1, tk.h2, tk.h3, tk.h4, tk.h5, tk.h6, tk.paragraph, tk.ul: hvalue: string 
    of tk.pre: 
      lang, codeBlock: string
    else:
      discard

# '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
const forwardSet = {'#', '<', '-', '[', '*', '+', '=', '`', '~', '!'}


proc tokenParagraph(m: string, pos: var int): Token = 
  var tok, tmp: string
  while true:
    pos += parseUntil(m, tmp, {'\n'}, pos)
    pos += skipWhitespace(m, pos)
    tok &= tmp
    if pos >= m.len or m[pos] in forwardSet:
      break
 
  result = Token(kind: tk.paragraph, hvalue: tok)



proc tokenize(m: string): seq[Token] = 
  let length = m.len
  var 
    pos = 0
  while pos < length:
    case m[pos]:
    of '#':
      let 
        level = skipWhile(m, {'#'}, pos)
        space = skipWhitespace(m, pos + level)
      pos += space + level
      var tok: string
      pos += parseUntil(m, tok, {'\n'}, pos) 
      case level:
      of 1: result.add(Token(kind: tk.h1, hvalue: tok))
      of 2: result.add(Token(kind: tk.h2, hvalue: tok))
      of 3: result.add(Token(kind: tk.h3, hvalue: tok))
      of 4: result.add(Token(kind: tk.h4, hvalue: tok))
      of 5: result.add(Token(kind: tk.h5, hvalue: tok))
      of 6: result.add(Token(kind: tk.h6, hvalue: tok))
      else: raise
    of '`':
      let level = skipWhile(m, {'`'}, pos)
      case level:
      of 1, 2: discard
      of 3:
        pos += level
        pos += skipWhitespace(m, pos)
        var 
          lang, codeBlock: string
          tmp: string
        pos += parseUntil(m, lang, {'\n'}, pos) + 1
        while true:
          pos += parseUntil(m, tmp, {'\n'}, pos)
          pos += skipWhitespace(m, pos)
          codeBlock &= tmp
          if pos >= m.len:
            break
          elif parseUntil(m, tmp, "```", pos) != pos:
            pos += 3
            break
        result.add Token(kind: tk.pre, lang: lang, codeBlock: codeBlock)
      else: discard

    of '-':
      pos += 1
      let space = skipWhitespace(m, pos)
      if space == 0:
        result.add tokenParagraph(m, pos) 
      else:
        pos += space
        var tok: string
        pos += parseUntil(m, tok, {'\n'}, pos)
        result.add Token(kind: tk.ul, hvalue: tok)
    of ' ', '\n':
      pos += 1
    else:
      result.add tokenParagraph(m, pos)


      



when isMainModule:
  echo tokenize("  ### 我是测试\n正文\n在这里- 12 \n - 14 \n - 17\n```nim\nif a > 4: echo hsh\n ```")
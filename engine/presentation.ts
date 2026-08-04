// Thali Code — the exit screen (session epilogue).
//
// Upstream keeps a PRIVATE copy of the wordmark here, separate from logo.ts, so
// patching logo.ts alone still left "opencode" on screen when you quit. The left
// word is ours ("thali"); the right word ("code") reuses upstream's glyphs
// unchanged, since it is part of our name too. Colours match the entry splash.
const logo = {
  left: [" ▄   ▄         ▄    ▄   ", "▀█▀  █▀▀█ ▄▀▀█ █        ", " █_  █__█ █__█ █    █   ", " ▀▀  ▀~~▀ ▀▀▀▀ ▀    ▀   "],
  right: ["             ▄     ", "█▀▀▀ █▀▀█ █▀▀█ █▀▀█", "█___ █__█ █__█ █^^^", "▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀"],
}

const reset = "\x1b[0m"
const bold = "\x1b[1m"
const dim = "\x1b[90m"
// Thali teal, same values as the entry logo: dim #2FA88C, bright #20E3C8.
const brandDim = "\x1b[38;2;47;168;140m"
const brandBright = "\x1b[38;2;32;227;200m"

function wordmark(pad = "") {
  const draw = (line: string, fg: string, shadow: string, bg: string) =>
    [...line]
      .map((char) => {
        if (char === "_") return `${bg} ${reset}`
        if (char === "^") return `${fg}${bg}▀${reset}`
        if (char === "~") return `${shadow}▀${reset}`
        if (char === " ") return " "
        return `${fg}${char}${reset}`
      })
      .join("")

  return logo.left.map((line, index) => {
    const left = draw(line, brandDim, "\x1b[38;5;235m", "\x1b[48;5;235m")
    const right = draw(logo.right[index] ?? "", brandBright, "\x1b[38;5;238m", "\x1b[48;5;238m")
    return `${pad}${left} ${right}`
  })
}

export function sessionEpilogue(input: { title: string; sessionID?: string }) {
  const weak = (text: string) => `${dim}${text.padEnd(10, " ")}${reset}`
  return [
    ...wordmark("  "),
    "",
    `  ${weak("Session")}${bold}${input.title}${reset}`,
    `  ${weak("Continue")}${bold}thali -s ${input.sessionID}${reset}`,
    "",
  ].join("\n")
}

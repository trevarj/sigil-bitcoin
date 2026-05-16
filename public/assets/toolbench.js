const root = document.getElementById("toolbench");

const TOOLS = [
  {
    group: "Hashing",
    title: "HASH160",
    tool: "hash.hash160",
    inputLabel: "Hex bytes",
    input: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
  },
  {
    group: "Hashing",
    title: "HASH256",
    tool: "hash.hash256",
    inputLabel: "Hex bytes",
    input: "0000000000000000000000000000000000000000000000000000000000000000"
  },
  {
    group: "Hashing",
    title: "Tagged hash",
    tool: "hash.tagged",
    inputLabel: "Hex bytes",
    input: "0000000000000000000000000000000000000000000000000000000000000000",
    fields: [{ key: "a", label: "Tag", value: "TapTweak" }]
  },
  {
    group: "Encoding",
    title: "Hex decode",
    tool: "encoding.hex",
    inputLabel: "Hex bytes",
    input: "deadbeef"
  },
  {
    group: "Encoding",
    title: "Base58 encode",
    tool: "encoding.base58.encode",
    inputLabel: "Hex bytes",
    input: "00000000000000000000"
  },
  {
    group: "Encoding",
    title: "Base58 decode",
    tool: "encoding.base58.decode",
    inputLabel: "Base58",
    input: "1111111111"
  },
  {
    group: "Encoding",
    title: "Base58Check encode",
    tool: "encoding.base58check.encode",
    inputLabel: "Payload hex",
    input: "751e76e8199196d454941c45d1b3a323f1433bd6",
    fields: [{ key: "a", label: "Version", value: "0" }]
  },
  {
    group: "Encoding",
    title: "Base58Check decode",
    tool: "encoding.base58check.decode",
    inputLabel: "Base58Check",
    input: "1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH"
  },
  {
    group: "Encoding",
    title: "SegWit encode",
    tool: "encoding.segwit.encode",
    inputLabel: "Witness program hex",
    input: "751e76e8199196d454941c45d1b3a323f1433bd6",
    fields: [
      { key: "a", label: "HRP", value: "bc" },
      { key: "b", label: "Version", value: "0" }
    ]
  },
  {
    group: "Encoding",
    title: "SegWit decode",
    tool: "encoding.segwit.decode",
    inputLabel: "Address",
    input: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  },
  {
    group: "Keys",
    title: "Private key to addresses",
    tool: "keys.private",
    inputLabel: "Private key hex",
    input: "0000000000000000000000000000000000000000000000000000000000000001",
    fields: [{ key: "a", label: "Network", value: "mainnet", options: ["mainnet", "testnet"] }]
  },
  {
    group: "Keys",
    title: "WIF decode",
    tool: "keys.wif.decode",
    inputLabel: "WIF",
    input: "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn"
  },
  {
    group: "Keys",
    title: "BIP39 entropy",
    tool: "keys.bip39.entropy",
    inputLabel: "Entropy hex",
    input: "00000000000000000000000000000000"
  },
  {
    group: "Keys",
    title: "BIP39 mnemonic",
    tool: "keys.bip39.mnemonic",
    inputLabel: "Mnemonic",
    input: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    fields: [{ key: "a", label: "Passphrase", value: "TREZOR" }]
  },
  {
    group: "Keys",
    title: "BIP32 derive",
    tool: "keys.bip32",
    inputLabel: "Seed hex",
    input: "000102030405060708090a0b0c0d0e0f",
    fields: [
      { key: "a", label: "Path", value: "m/84'/0'/0'/0/0" },
      { key: "b", label: "Network", value: "mainnet", options: ["mainnet", "testnet"] }
    ]
  },
  {
    group: "Script",
    title: "Script template",
    tool: "script.template",
    inputLabel: "Hash/program hex",
    input: "751e76e8199196d454941c45d1b3a323f1433bd6",
    fields: [{ key: "a", label: "Template", value: "p2wpkh", options: ["p2pkh", "p2sh", "p2wpkh", "p2wsh", "p2tr", "push"] }]
  },
  {
    group: "Transactions",
    title: "Parse transaction",
    tool: "tx.parse",
    inputLabel: "Transaction hex",
    input: "020000000100000000000000000000000000000000000000000000000000000000000000000000000000feffffff01e803000000000000160014751e76e8199196d454941c45d1b3a323f1433bd600000000"
  },
  {
    group: "Transactions",
    title: "Build demo transaction",
    tool: "tx.demo",
    inputLabel: "Input",
    input: ""
  },
  {
    group: "PSBT",
    title: "Parse PSBT",
    tool: "psbt.parse",
    inputLabel: "PSBT hex",
    input: ""
  },
  {
    group: "PSBT",
    title: "Sign P2WPKH demo PSBT",
    tool: "psbt.demo-p2wpkh",
    inputLabel: "Input",
    input: ""
  },
  {
    group: "Miniscript",
    title: "Compile Miniscript",
    tool: "miniscript.compile",
    inputLabel: "Miniscript",
    input: "multi_a(1,0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,03f028892bad7ed57d2fb57bf33081d5cfcf6f9ed3d3d7f159c2e2fff579dc341a)"
  },
  {
    group: "Descriptors",
    title: "Inspect descriptor",
    tool: "descriptor.inspect",
    inputLabel: "Descriptor",
    input: "tr(0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,multi_a(1,0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,03f028892bad7ed57d2fb57bf33081d5cfcf6f9ed3d3d7f159c2e2fff579dc341a))"
  }
];

function toolSlug(tool) {
  return tool.replace(/\./g, "-");
}

class SigilRuntime {
  constructor(wasmRoot) {
    this.wasmRoot = wasmRoot;
    this.instance = null;
    this.exports = null;
    this.stdout = [];
    this.stderr = [];
    this.encoder = new TextEncoder();
    this.decoder = new TextDecoder();
  }

  async load() {
    const shim = await import("https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.2/+esm");
    const bundle = await this.loadBundle(`${this.wasmRoot}lib.bundle`, shim.File, shim.Directory);
    const fds = [
      new shim.OpenFile(new shim.File([])),
      shim.ConsoleStdout.lineBuffered((line) => this.stdout.push(line)),
      shim.ConsoleStdout.lineBuffered((line) => this.stderr.push(line)),
      new shim.PreopenDirectory("/lib", bundle)
    ];
    const wasi = new shim.WASI(["sigil-bitcoin-demo"], [], fds);
    const wasmBytes = await fetch(`${this.wasmRoot}sigil-bitcoin-demo.wasm`).then((res) => {
      if (!res.ok) throw new Error(`WASM not found: ${res.status}`);
      return res.arrayBuffer();
    });
    const module = await WebAssembly.compile(wasmBytes);
    this.instance = await WebAssembly.instantiate(module, {
      wasi_snapshot_preview1: wasi.wasiImport
    });
    this.exports = this.instance.exports;
    wasi.start(this.instance);
  }

  async loadBundle(url, FileClass, DirectoryClass) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`module bundle not found: ${res.status}`);
    const data = new Uint8Array(await res.arrayBuffer());
    const root = new Map();
    let offset = 0;
    const u16 = () => data[offset++] | (data[offset++] << 8);
    const u32 = () => data[offset++] | (data[offset++] << 8) | (data[offset++] << 16) | (data[offset++] << 24);
    const count = u32();
    for (let i = 0; i < count; i += 1) {
      const pathLen = u16();
      const path = this.decoder.decode(data.slice(offset, offset + pathLen));
      offset += pathLen;
      const size = u32();
      const bytes = data.slice(offset, offset + size);
      offset += size;
      this.addBundleFile(root, path, bytes, FileClass, DirectoryClass);
    }
    return root;
  }

  addBundleFile(root, path, bytes, FileClass, DirectoryClass) {
    const parts = path.split("/").filter(Boolean);
    if (parts.length === 0) return;
    let dir = root;
    for (const part of parts.slice(0, -1)) {
      let next = dir.get(part);
      if (!next) {
        next = new DirectoryClass(new Map());
        dir.set(part, next);
      }
      dir = next.contents;
    }
    dir.set(parts[parts.length - 1], new FileClass(bytes, { readonly: true }));
  }

  cString(value) {
    const bytes = this.encoder.encode(`${value}\0`);
    const ptr = this.exports.malloc(bytes.length);
    new Uint8Array(this.exports.memory.buffer, ptr, bytes.length).set(bytes);
    return [ptr, bytes.length];
  }

  eval(code) {
    this.stdout = [];
    this.stderr = [];
    const [ptr] = this.cString(code);
    try {
      const status = this.exports.sigil_web_eval(ptr);
      const output = this.stdout.join("\n");
      const error = this.stderr.join("\n");
      if (status !== 0) throw new Error(error || output || `sigil_web_eval returned ${status}`);
      const match = output.match(/__SIGIL_BITCOIN_RESULT__(.*)__END_SIGIL_BITCOIN_RESULT__/s);
      if (!match) throw new Error(output || "Sigil returned no tool result");
      return JSON.parse(match[1]);
    } finally {
      this.exports.free(ptr);
    }
  }

  run(tool, values) {
    const args = ["input", "a", "b", "c"].map((key) => schemeString(values[key] || ""));
    return this.eval(`(import (sigil bitcoin demo)) (demo-dispatch ${schemeString(tool)} ${args.join(" ")})`);
  }
}

function schemeString(value) {
  return `"${String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, "\\n")}"`;
}

function pretty(value) {
  return JSON.stringify(value, null, 2);
}

function renderField(tool, field) {
  const id = `${tool.tool}-${field.key}`;
  const label = document.createElement("label");
  label.htmlFor = id;
  label.textContent = field.label;
  const input = field.options ? document.createElement("select") : document.createElement("input");
  input.id = id;
  input.name = field.key;
  if (field.options) {
    for (const option of field.options) {
      const node = document.createElement("option");
      node.value = option;
      node.textContent = option;
      input.appendChild(node);
    }
  }
  input.value = field.value || "";
  return [label, input];
}

function renderTool(tool, runtimeRef, options = {}) {
  const card = document.createElement("article");
  card.className = "tool-card";
  card.dataset.group = tool.group;

  const heading = document.createElement("h3");
  heading.textContent = tool.title;
  const group = document.createElement("p");
  group.textContent = `${tool.group} / ${tool.tool}`;
  if (!options.single) {
    const details = document.createElement("a");
    details.className = "tool-detail";
    details.href = `${options.toolsRoot || "tools/"}${toolSlug(tool.tool)}.html`;
    details.textContent = "Details";
    group.append(" / ", details);
  }
  const inputLabel = document.createElement("label");
  inputLabel.textContent = tool.inputLabel;

  const input = tool.input.length > 72 ? document.createElement("textarea") : document.createElement("input");
  input.name = "input";
  input.value = tool.input;

  const actions = document.createElement("div");
  actions.className = "tool-actions";
  const run = document.createElement("button");
  run.type = "button";
  run.textContent = "Run";
  const reset = document.createElement("button");
  reset.type = "button";
  reset.className = "secondary";
  reset.textContent = "Example";
  actions.append(run, reset);

  const output = document.createElement("pre");
  output.className = "tool-output";
  output.textContent = options.single ? "Loading runtime." : "Ready. Runtime loads on first run.";

  card.append(heading, group, inputLabel, input);
  for (const field of tool.fields || []) {
    const [label, control] = renderField(tool, field);
    card.append(label, control);
  }
  card.append(actions, output);

  reset.addEventListener("click", () => {
    input.value = tool.input;
    for (const field of tool.fields || []) {
      const control = card.querySelector(`[name="${field.key}"]`);
      if (control) control.value = field.value || "";
    }
  });

  run.addEventListener("click", async () => {
    const values = { input: input.value };
    for (const field of tool.fields || []) {
      const control = card.querySelector(`[name="${field.key}"]`);
      values[field.key] = control ? control.value : "";
    }
    output.classList.remove("tool-error");
    try {
      output.textContent = runtimeRef.current ? "Running..." : "Loading WASM runtime...";
      await runtimeRef.ensure();
      output.textContent = "Running...";
      const result = runtimeRef.current.run(tool.tool, values);
      output.textContent = pretty(result.ok ? result.result : result);
      if (!result.ok) output.classList.add("tool-error");
    } catch (err) {
      output.classList.add("tool-error");
      output.textContent = err.message;
    }
  });

  return card;
}

async function boot() {
  if (!root) return;

  const status = document.createElement("div");
  status.className = "tool-status";
  const grid = document.createElement("div");
  grid.className = "tool-grid";
  const runtimeRef = { current: null, loading: null, ensure: null };
  const selectedTool = root.dataset.tool || "";
  const visibleTools = selectedTool ? TOOLS.filter((tool) => tool.tool === selectedTool) : TOOLS;
  const single = selectedTool !== "";
  const toolsRoot = root.dataset.toolsRoot || "tools/";
  if (single) grid.classList.add("single");

  root.append(status, grid);
  if (visibleTools.length === 0) {
    status.innerHTML = `<div><strong>Unknown tool</strong><span>${selectedTool}</span></div>`;
    return;
  }
  for (const tool of visibleTools) {
    grid.appendChild(renderTool(tool, runtimeRef, { single, toolsRoot }));
  }

  const wasmRoot = root.dataset.wasmRoot || "assets/wasm/";
  status.innerHTML = single
    ? "<div><strong>Loading WASM runtime</strong><span>Fetching Sigil runtime and module bundle.</span></div>"
    : "<div><strong>WASM runtime idle</strong><span>Tools will load the shared runtime on first run.</span></div>";

  runtimeRef.ensure = async () => {
    if (runtimeRef.current) return runtimeRef.current;
    if (!runtimeRef.loading) {
      const runtime = new SigilRuntime(wasmRoot);
      status.innerHTML = "<div><strong>Loading WASM runtime</strong><span>Fetching Sigil runtime and module bundle.</span></div>";
      runtimeRef.loading = runtime.load()
        .then(() => {
          runtimeRef.current = runtime;
          status.innerHTML = "<div><strong>WASM runtime ready</strong><span>Tools run locally in this browser tab.</span></div>";
          for (const output of grid.querySelectorAll(".tool-output")) {
            if (!output.classList.contains("tool-error")) output.textContent = "Ready.";
          }
          return runtime;
        })
        .catch((err) => {
          status.innerHTML = `<div><strong>WASM runtime unavailable</strong><span>${err.message}</span></div>`;
          for (const output of grid.querySelectorAll(".tool-output")) {
            output.classList.add("tool-error");
            output.textContent = "Run scripts/pages-build.sh to generate public/assets/wasm/ artifacts.";
          }
          throw err;
        });
    }
    return runtimeRef.loading;
  };

  if (single || root.dataset.autoload === "true") {
    runtimeRef.ensure().catch(() => {});
  }
}

boot();

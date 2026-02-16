# render-md.nvim

Neovim 内で Markdown ファイルを Notion のようなスタイルでリアルタイムにレンダリングするプラグインです。編集のしやすさと閲覧時の美しさを両立させることを目指しています。

## ✨ 特徴

- **Notionライクなリッチな装飾**:
  - 見出し（H1, H2, H3）の背景色とレベル別アイコン付与。
  - 箇条書きリストのドットをカスタムアイコン（•）に置換。
  - チェックボックス（タスクリスト）をインタラクティブなアイコン（☐, ☑）に置換。
  - 引用ブロック（Blockquote）のサイドバー表示。
  - コードブロックの背景色変更。
  - **モダンなテーブル表示**: パイプテーブルをクリーンなグリッドとヘッダー強調スタイルで表示。
- **スマート・アンレンダリング (Smart Unrendering)**:
  - **インサートモードに入ると自動的にバッファ全体の装飾を解除**し、生の Markdown テキストを表示。
  - モードを抜けると即座にリッチな表示を復元。編集時の視認性と正確性を極限まで高めています。
- **Treesitter 連携**: 高精度な構文解析に基づき、バッファを汚さず装飾（Extmarks）のみで描画。

## 📋 必要条件

- Neovim 0.9.0 以上
- `nvim-treesitter` (markdown および markdown_inline パーサー)
- [Nerd Fonts](https://www.nerdfonts.com/) (アイコン表示に必須)

## 📦 インストール

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "your-username/render-md.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = "markdown",
    config = function()
        require("render-md").setup({
            -- オプション設定（任意）
        })
    end
}
```

## ⚙️ 設定

デフォルト設定は以下の通りです。`setup()` でカスタマイズ可能です。

```lua
require("render-md").setup({
    enabled = true,
    highlights = {
        h1 = { bg = "#3d2b1f", fg = "#ffaa88" },
        h2 = { bg = "#1f2b3d", fg = "#88aaff" },
        h3 = { bg = "#2b3d1f", fg = "#aaff88" },
        bullet = { fg = "#569cd6" },
        quote = { fg = "#6a9955" },
        checkbox = { fg = "#ce9178" },
        code = { bg = "#1e1e1e" },
    },
    icons = {
        h1 = "󰉫 ",
        h2 = "󰉬 ",
        h3 = "󰉭 ",
        bullet = "• ",
        unchecked = "☐ ",
        checked = "☑ ",
        quote = "▎",
        code = "󰨰 ",
    }
})
```

## ⌨️ コマンド

- `:RenderMDEnable` - レンダリングを有効にする
- `:RenderMDDisable` - レンダリングを完全に無効にする
- `:RenderMDToggle` - 有効/無効を切り替える

## 🤝 開発について

このプラグインは、ユーザーの編集体験を損なうことなく、Markdown をより美しく、構造的に表示することを目的に作成されました。
不具合や改善の提案があれば、ぜひお知らせください。

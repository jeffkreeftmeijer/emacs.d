
# ~/.emacs.d

- [Installation](#org1f0fac6)
  - [Building Emacs from Git with Nix](#org6bc7fa6)
  - [Enabling XWidgets in Emacs on macOS with Nix](#orgd424d35)
  - [Applying Emacs Plus patches](#orgf2ea9fb)
  - [Emacs with bundled configuration](#org0955e74)
  - [Configured Emacs](#org43d8959)
- [Appearance](#org2f3cd39)
  - [Frames](#org4377b63)
  - [Fonts](#org76a0c30)
  - [Variable pitch](#org5fbfd05)
  - [Themes](#org2b1f208)
  - [Layout](#orgb759bc1)
- [Modal editing](#org043e741)
  - [Evil mode](#orgefb5aae)
  - [Evil-commentary](#org5d9ab6a)
  - [Cursors](#org7c32e82)
- [Completion](#org480124e)
  - [Vertical completion](#orga86ff66)
  - [Contextual information](#orgda18320)
  - [Enhanced navigation commands](#org7864369)
  - [Pattern matching](#orgbd02852)
  - [Minibuffer actions](#org5e2469b)
  - [Minibuffer history](#orgd81a361)
  - [Completion at point](#org620e2e0)
- [Development](#orgdaa499f)
  - [Major modes](#orgbb80caa)
  - [Environments](#org5bcb9ed)
  - [Language servers](#orgd9a22b3)
- [Version control](#orgd72c9b1)
- [Shell](#org8e94f14)
  - [Terminal emulation](#orga1fe769)
  - [History](#org22d649e)
- [Dired](#orga456606)
- [Org](#orgce2a837)
  - [Note-taking](#org202efa9)
  - [Task management](#org7090598)
  - [Modern defaults for Org exports](#orgfa7a867)
  - [Source code](#org4524681)
- [Email](#org0863a90)
- [Enhancements](#org4e9f42d)
  - [Backups](#org3ec9d5c)
  - [Key suggestions](#org292d6a2)
  - [Projects](#org9654aa4)
  - [Precise scrolling](#orgd730eb5)
  - [Indentation](#org290e677)
- [Benchmarking](#orgf5ab2d5)



<a id="org1f0fac6"></a>

## Installation

This whole Emacs configuration, including the configuration file and the included packages is a Nix [derivation](https://nixos.org/manual/nix/stable/language/derivations.html). By installing Emacs through Nix, the editor, its packages and the configuration are bundled together in a single bundle. This allows for quick installs and reproducable builds.

As an example, to try out this Emacs configuration without affecting the rest of your system, run the following command. This downloads and compiles Emacs, including packages and the configuration, and starts the resulting Emacs.app.

```shell
nix run github:jeffkreeftmeijer/.emacs.d
```


<a id="org6bc7fa6"></a>

### Building Emacs from Git with Nix

Instead of using the [stable Emacs from Nixpkgs](https://search.nixos.org/packages?channel=23.11&show=emacs&from=0&size=50&sort=relevance&type=packages&query=emacs), this configuration uses [emacs-overlay](https://github.com/nix-community/emacs-overlay) to build Emacs from its master branch. The overlay updates daily, but this configuration only updates sporadically, when there's reason to do so, to keep everything as stable as possible.

I'm inclined to use a stable version of Emacs instead of building from Git, as I'm not specifically looking to be on the bleeding edge. However, newly added features tend to pull me in.

Currently, there are two reasons I'm currently running on a prerelease version:

1.  Emacs master updated its included version of the modus-themes, including the tinted variants of modus-vivendi and modus-operandi, which are my preferred themes. Running Emacs master therefor requires one less dependency.
2.  [Completion-preview.el](https://git.savannah.gnu.org/cgit/emacs.git/log/lisp/completion-preview.el), a fish-like completion-at-point package, was merged into master in [e82d807a2845673e2d55a27915661b2f1374b89a](https://git.savannah.gnu.org/cgit/emacs.git/commit/lisp/completion-preview.el?id=e82d807a2845673e2d55a27915661b2f1374b89a).

To build a Nix derivation that intalls Emacs from Git using Emacs-overlay, import `nixpkgs`, and then apply the overlay from a tarball. Then, return `pkgs.emacs-git`:

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacs-git
```

The version of emacs-overlay (and thus Emacs itself) is determined by the version specified in the master branch. That version is then locked in the `flake.lock` file until it's explicitly updated:

```shell
nix flake lock --update-input emacs-overlay
```

Assuming the derivation is saved to a file named `emacs-git.nix`, it can be built through `nix build`:


<a id="orgd424d35"></a>

### Enabling XWidgets in Emacs on macOS with Nix

Nix disables the `withXwidgets` option for Emacs on macOS, so simply enabling it won't work yet:

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacs-git.overrideAttrs(old: {
  withXwidgets = true;
})
```

In the meantime, circumvent Nix's option by manually adding the build flag. As expected, enabling XWidgets also requires the WebKit framework as a build input:

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacs-git.overrideAttrs(old: {
  buildInputs = old.buildInputs ++ [
    pkgs.darwin.apple_sdk.frameworks.WebKit
  ];

  configureFlags = old.configureFlags ++ ["--with-xwidgets"];
})
```


<a id="orgf2ea9fb"></a>

### Applying Emacs Plus patches

[Emacs Plus](https://github.com/d12frosted/homebrew-emacs-plus) is a Homebrew formula to build Emacs on macOS, which applies a couple of patches while building. First, download the patches for the correct Emacs version. In this case, get the patches for Emacs 30:

```shell
curl https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/system-appearance.patch -o patches/system-appearance.patch
curl https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/round-undecorated-frame.patch -o patches/round-undecorated-frame.patch
curl https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/poll.patch -o patches/poll.patch
curl https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch -o patches/fix-window-role.patch
```

Then, override the attributes in `pkgs.emacs-git` when using emacs-overlay&#x2014;or `pkgs.emacs` when building Emacs from Nixpkgs&#x2014;to add all path files to the package's patches list:

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacs-git.overrideAttrs(old: {
  patches = old.patches ++ [
    ./patches/system-appearance.patch
    ./patches/round-undecorated-frame.patch
    ./patches/poll.patch
    ./patches/fix-window-role.patch
  ];
})
```

Assuming the derivation is saved to a file named `emacs-patched.nix`, it can be built through `nix build`:

```shell
nix build --file emacs-patched.nix
open /result/Applications/Emacs.app
```


<a id="org0955e74"></a>

### Emacs with bundled configuration

The `emacsWithPackagesFromUsePackage` function parses configuration files in search of packages to bundle with Emacs. For example, to package Emacs with Evil and enable `evil-mode` on startup, add a `use-package` statement as the emacs configuration:

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacsWithPackagesFromUsePackage {
  package = pkgs.emacs-git;
  config = ''
  (use-package evil
    :ensure t
    :init
    (evil-mode 1))
  '';
  defaultInitFile = true;
}
```

Assuming the derivation is saved to a file named `emacs-evil.nix`, it can be built through `nix build`:

```shell
nix build --file emacs-evil.nix
open /result/Applications/Emacs.app
```


<a id="org43d8959"></a>

### Configured Emacs

By combining the features in Emacs overlay, this configuration produces *configured Emacs*, a version of Emacs with macOS-specific patches applied, XWidgets enabled, packages installed and a full configuration loaded. The included configuration file is [`default.el`](https://github.com/jeffkreeftmeijer/.emacs.d/blob/main/default.el), which is generated from the rest of this configuration.

```nix
{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];
} }:

pkgs.emacsWithPackagesFromUsePackage {
  package = (
    pkgs.emacs-git.overrideAttrs(old: {
      patches = old.patches ++ [
	./patches/system-appearance.patch
	./patches/round-undecorated-frame.patch
	./patches/poll.patch
	./patches/fix-window-role.patch
      ];

      buildInputs = old.buildInputs ++ [
	pkgs.darwin.apple_sdk.frameworks.WebKit
      ];

      configureFlags = old.configureFlags ++ ["--with-xwidgets"];
    })
  );

  config = ./default.el;
  defaultInitFile = true;
}
```


<a id="org2f3cd39"></a>

## Appearance


<a id="org4377b63"></a>

### Frames

Disable the scroll bar, the tool bar, and the menu bar:

```emacs-lisp
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
```


<a id="org76a0c30"></a>

### Fonts

Use [Iosevka](https://typeof.net/Iosevka/) as a monospace font (*fixed* in Emacs lingo), and Iosevka's "Aile" variant as a (quasi-)proportional font (*variable-pitch* in Emacs lingo).

Both variants are used with their *regular* weights, *expanded* widths, and a height of 150 (15 points × 10):

```emacs-lisp
(defun jk/set-face-font (face family)
  (set-face-attribute
   face nil
   :family family :weight 'regular :width 'expanded :height 150))

(jk/set-face-font 'default "Iosevka")
(jk/set-face-font 'fixed-pitch "Iosevka")
(jk/set-face-font 'variable-pitch "Iosevka Aile")
```

The `face-font-family-alternatives` variable provides fallback fonts if the preferred fonts aren't available. This produces a font list akin to CSS font-families, starting with the preferred font and falling back to an option that is most likely to be available on any system. Having a list of fallback fonts like this removes the need to explicitly depend on fonts being available.

This configuration falls back to Apple's SF Mono and SF Pro if the Iosevka fonts aren't available. Since the Apple fonts need to be downloaded explicitly, they aren't more likely to be there than the Iosevka ones, but they're included as they were the previous favorite.

If the SF fonts aren't available, the fixed font falls back to Menlo before the default monospace font (which is most likely Courier). The variable pitch font falls back to SF Pro, Helvetica, and finally Arial:

```emacs-lisp
(custom-set-variables
  '(face-font-family-alternatives
  '  '(("Iosevka" "SF Mono" "Menlo" "monospace")
  '    ("Iosevka Aile" "SF Pro" "Helvetica" "Arial"))))
```


<a id="org5fbfd05"></a>

### Variable pitch

To use proportional fonts (as opposed to monospaced fonts) for non-code text, enable `variable-pitch-mode` for selected modes. While this mode is enabled, the `default` font face inherits from `variable-pitch` instead of `fixed-pitch`.

An often-recommended approach is to hook into `text-mode`, which is the major mode most text-based modes inherit from:

```emacs-lisp
(add-hook 'text-mode-hook #'variable-pitch-mode))
```

Doing so automatically enables `variable-pitch-mode` thenever `text-mode` is enabled.

This works, but it's a bit too eager for my liking. The above configuration enables `variable-pitch-mode` when editing Org files, but also when writing commit messages and editing YAML files. I consider text in the latter two as code, so I'd prefer to have those displayed in a monospace font.

Instead of hooking into `text-mode`, explicitly select the modes to use proportional fonts in Org and Markdown mode:

```emacs-lisp
(add-hook 'org-mode-hook #'variable-pitch-mode)
(add-hook 'markdown-mode-hook #'variable-pitch-mode)
```


<a id="org2b1f208"></a>

### Themes

The [Modus themes](https://protesilaos.com/emacs/modus-themes) are a set of beautiful and customizable themes, which are shipped with Emacs since version 28.

The modus themes consist of two types: Modus Operandi is a light theme, and Modus Vivendi is its dark counterpart. The tinted variants shift the background colors from white and black to a more pleasant light ochre and dark blue.

When using the version of the Modus themes that's included in Emacs, the themes need to be [explicitly required using `require-theme`](https://protesilaos.com/emacs/modus-themes#h:b66b128d-54a4-4265-b59f-4d1ea2feb073):

```emacs-lisp
(require-theme 'modus-themes)
```

To select `modus-operandi-tinted` as the default theme, load it with the `load-theme` function:

```emacs-lisp
(load-theme 'modus-operandi-tinted)
```

An interactive function named `modus-themes-toggle` switches between the light and dark themes. By default, the function switches between the non-tinted versions, but that can be overwritten to use the tinted versions through the `modus-themes-to-toggle` variable:

```emacs-lisp
(setq modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
```


#### Switching between dark and light mode

[Auto-dark](https://github.com/LionyxML/auto-dark-emacs) automatically switches between dark and light themes based on the operating system's appearance.

```emacs-lisp
(auto-dark-mode 1)
```

It uses the *wombat* and *leuven* themes by default, but these are configured to use the modus themes with the `auto-dark-light-theme` and `auto-dark-dark-theme` variables.

```emacs-lisp
(setq (auto-dark-light-theme 'modus-operandi-tinted)
(setq (auto-dark-dark-theme 'modus-vivendi-tinted))
```

With auto-dark in place, Emacs' theme can be switched by toggling the system-wide dark mode instead of using `modus-themes-toggle`. The `jk/dark` and `jk/light` functions run an apple script to turn dark mode on and off from Emacs:

```emacs-lisp
(defun jk/dark ()
  "Switch to macOS' dark appearance."
  (interactive)
  (do-applescript
   "tell application \"System Events\"
  tell appearance preferences
    set dark mode to true
  end tell
end tell"))

(defun jk/light ()
  "Switch to macOS' light appearance."
  (interactive)
  (do-applescript
   "tell application \"System Events\"
  tell appearance preferences
    set dark mode to false
  end tell
end tell"))
```


#### Customization

The Modus themes can optionally inherit from the `fixed-pitch` face for some faces, which allows for turning on `variable-pitch-mode` while keeping some text monospaced. To turn it on, set `modus-themes-mixed-fonts`, but make sure it's set before loading one of the modus themes:

```emacs-lisp
(setq modus-themes-mixed-fonts t)
```

The Modus themes come with the option to use italic and bold constructs, which is turned off by default. Enabling produces italic type for comments and contextual information, and bold type in syntax highlighting.

```emacs-lisp
(setq
 modus-themes-italic-constructs t
 modus-themes-bold-constructs t)
```

Note that any configuration options to the themes themselves need to happen before the theme is loaded, or the theme needs to be reloaded through `load-theme` after setting the customizations.


<a id="orgb759bc1"></a>

### Layout

The [spacious-padding](https://protesilaos.com/emacs/spacious-padding) package adds spacing around windows and frames, as well as padding the mode line.

Turn on `spacious-padding-mode` to add spacing around windows and frames:

```emacs-lisp
(spacious-padding-mode 1)
```

Turn on `spacious-padding-subtile-mode-line` for a more subtile mode line:

```emacs-lisp
(setq spacious-padding-subtle-mode-line t)
```


<a id="org043e741"></a>

## Modal editing


<a id="orgefb5aae"></a>

### Evil mode

Emacs is the best Vim emulator, and [Evil](https://github.com/emacs-evil/evil) is the best Vim mode. After installing Evil, turn on `evil-mode` globally:

Instead of enabling Evil's gloval `evil-mode` hook, turn it on per buffer. By hooking into both *prog-mode* and *text-mode*, Evil mode is only turned on for programming and text editing buffers.

```emacs-lisp
(add-hook 'prog-mode-hook 'turn-on-evil-mode)
(add-hook 'text-mode-hook 'turn-on-evil-mode)
```


<a id="org5d9ab6a"></a>

### Evil-commentary

[Evil-commentary](https://github.com/linktohack/evil-commentary) is an Evil port of [vim-commentary](https://github.com/tpope/vim-commentary) which adds key bindings to call Emacs’ built in `comment-or-uncomment-region` function. Turn it on by calling `evil-commentary-mode`:

```emacs-lisp
(evil-commentary-mode 1)
```


<a id="org7c32e82"></a>

### Cursors

An example of an essential difference between Emacs and Vim is how they handle the location of the cursor (named point in Emacs). In Vim, the cursor is *on* a character, while Emacs' point is before it. In Evil mode, the cursor changes between a box in "normal mode" to a bar in "insert mode". Because Emacs is always in a kind of insert mode, make the cursor a bar:

```emacs-lisp
(setq-default cursor-type 'bar)
```


<a id="org480124e"></a>

## Completion


<a id="orga86ff66"></a>

### Vertical completion

[Vertico](https://github.com/minad/vertico) is a vertical completion library, based on Emacs' default completion system.

```emacs-lisp
(vertico-mode 1)
```


<a id="orgda18320"></a>

### Contextual information

[Marginalia](https://github.com/minad/marginalia) adds extra contextual information to minibuffer completions. For example, besides just showing command names when executing `M-x`, the package adds a description of the command and the key binding.

```emacs-lisp
(marginalia-mode 1)
```


<a id="org7864369"></a>

### Enhanced navigation commands

[Consult](https://github.com/minad/consult) provides enhancements to built-in search and navigation commands. There is [a long list of available commands](https://github.com/minad/consult?tab=readme-ov-file#available-commands), but this configuration mostly uses Consult for buffer switching with previews.

1.  Replace `switch-to-buffer` (`C-x b`) with `consult-buffer`:
    
    ```emacs-lisp
    (global-set-key (kbd "C-x b") 'consult-buffer)
    ```

2.  Replace `project-switch-to-buffer` (`C-x p b`) with `consult-project-buffer`:
    
    ```emacs-lisp
    (global-set-key (kbd "C-x p b") 'consult-project-buffer)
    ```

3.  Replace `goto-line` (`M-g g` and `M-g M-g`) with `consult-goto-line`:
    
    ```emacs-lisp
    (global-set-key (kbd "M-g g") 'consult-goto-line)
    (global-set-key (kbd "M-g M-g") 'consult-goto-line)
    ```

4.  Replace `project-find-regexp` (`C-x p g`) with `consult-ripgrep`:
    
    ```emacs-lisp
    (global-set-key (kbd "C-x p g") 'consult-ripgrep)
    ```


<a id="orgbd02852"></a>

### Pattern matching

[Orderless](https://github.com/oantolin/orderless) is a completion style that divides the search pattern in space-separated components, and matches regardless of their order. After installing it, add it as a completion style by setting `completion-styles`:

```emacs-lisp
(setq completion-styles '(orderless basic))
```


<a id="org5e2469b"></a>

### Minibuffer actions

[Embark](https://github.com/oantolin/embark) adds actions to minibuffer results. For example, when switching buffers with `switch-to-buffer` or `consult-buffer`, pressing `C-.` opens Embark's list of key bindings. From there, you can act on results in the minibuffer. In this exampke, pressing `k` kills the currently selected buffer.

```emacs-lisp
(global-set-key (kbd "C-.") 'embark-act)
```


<a id="orgd81a361"></a>

### Minibuffer history

Emacs' `savehist` feature saves minibuffer history to `~/emacs.d/history`. The history is then used to order vertical completion suggestions.

```emacs-lisp
(savehist-mode 1)
```


<a id="org620e2e0"></a>

### Completion at point

Emacs 30 includes `completion-preview.el`, since [e82d807a2845673e2d55a27915661b2f1374b89a](https://git.savannah.gnu.org/cgit/emacs.git/commit/lisp/completion-preview.el?id=e82d807a2845673e2d55a27915661b2f1374b89a), which adds grayed-out completion previews while typing, akin to the autocomplete in the Fish shell.

```emacs-lisp
(global-completion-preview-mode 1)
```


<a id="orgdaa499f"></a>

## Development


<a id="orgbb80caa"></a>

### Major modes


#### Treesitter

The [treesit-auto](https://github.com/renzmann/treesit-auto) package automatically installs and uses the tree-sitter equivalent of installed major modes. For example, it automatically installs and uses `rust-ts-mode` when a Rust file is opened and `rust-mode` is installed.

To turn it on globally, enable `global-treesit-auto-mode`:

```emacs-lisp
(global-treesit-auto-mode 1)
```

To automatically install missing major modes, enable `treesit-auto-install`. To have the package prompt before installing, set the variable to `'prompt`:

```emacs-lisp
(custom-set-variables
  '(treesit-auto-install 'prompt))
```


#### Additional major modes

In addition to the list of already installed major modes, this configuration adds adds more when they're needed<sup><a id="fnr.1" class="footref" href="#fn.1" role="doc-backlink">1</a></sup>.

1.  beancount-mode

    [Bencount-mode](https://github.com/beancount/beancount-mode) requires hooking up the mode manually, so enable it for each file with a `.beancount` extension:
    
    ```emacs-lisp
    (use-package beancount
      :ensure t
      :mode ("\\.beancount\\'" . beancount-mode))
    ```

2.  dockerfile-mode

    ```emacs-lisp
    (use-package dockerfile-mode
      :ensure t)
    ```

3.  elixir-mode

    ```emacs-lisp
    (use-package elixir-mode
      :ensure t)
    ```

4.  git-modes

    ```emacs-lisp
    (use-package git-modes
      :ensure t)
    ```

5.  markdown-mode

    There is currently no Emacs major mode for [MDX](https://github.com/mdx-js/mdx), so enable [Markdown-mode](https://jblevins.org/projects/markdown-mode/) for files with a `.mdx` extension:
    
    ```emacs-lisp
    (use-package markdown-mode
      :ensure t
      :mode ("\\.mdx\\'" . markdown-mode))
    ```

6.  nix-mode

    ```emacs-lisp
    (use-package nix-mode
      :ensure t)
    ```

7.  rust-mode

    ```emacs-lisp
    (use-package rust-mode
      :ensure t)
    ```

8.  typescript-mode

    ```emacs-lisp
    (use-package typescript-mode
      :ensure t)
    ```

9.  yaml-mode

    ```emacs-lisp
    (use-package yaml-mode
      :ensure t)
    ```


<a id="org5bcb9ed"></a>

### Environments

Programming environments set up with [Nix](https://nixos.org) and [direnv](https://direnv.net) alter the environment and available programs based on the current directory. To provide access to programs on a per-directory level, use the [Emacs direnv package](https://github.com/wbolster/emacs-direnv):

```emacs-lisp
(direnv-mode 1)
```


<a id="orgd9a22b3"></a>

### Language servers

Eglot is Emacs' built-in Language Server Protocol client. Language servers are added through the `eglot-server-programs` variable:

```emacs-lisp
(add-to-list 'eglot-server-programs '((rust-ts-mode rust-mode) "rust-analyzer"))
(add-to-list 'eglot-server-programs '((elixir-ts-mode elixir-mode) "elixir-ls"))
(add-to-list 'eglot-server-programs '((nix-mode) "nixd"))
```

Start eglot automatically for Nix an Rust files:

```emacs-lisp
(add-hook 'nix-mode #'eglot-ensure)
(add-hook 'rust-mode #'eglot-ensure)
(add-hook 'rust-ts-mode #'eglot-ensure)
```


#### Automatically format files on save in Eglot-enabled buffers

The `eglot-format-buffer` function doesn't check if Eglot is running in the current buffer. This means hooking using it as a global `after-save-hook` produces errors in the echo area whenever a file is saved while Eglot isn't enabled:

```emacs-lisp
(jsonrpc-error
 "No current JSON-RPC connection"
 (jsonrpc-error-code . -32603)
 (jsonrpc-error-message . "No current JSON-RPC connection"))
```

To remedy this, add a function that formats only when Eglot is enabled.

```emacs-lisp
(defun jk/maybe-format-buffer ()
  (when (bound-and-true-p eglot-managed-p)
    (eglot-format-buffer)))
```

This function is then added as a global `after-save-hook`.

```emacs-lisp
(add-hook 'after-save-hook 'jk/maybe-format-buffer)
```

Now, with the hook enabled, any Eglot-enabled buffer is formatted automatically on save.


<a id="orgd72c9b1"></a>

## Version control

[Magit](https://magit.vc) is a user interface for Git in Emacs. Even after years of using Git from the console, it's the quickest way to use Git, and it's one of the most sophisticated Emacs packages.

An interesting thing about Magit is that it doesn't have many configuration options. It doesn't need any, as it's a great experience out of the box.

```emacs-lisp
(use-package magit
  :ensure t)
```


<a id="org8e94f14"></a>

## Shell


<a id="orga1fe769"></a>

### Terminal emulation

Use [Eat](https://codeberg.org/akib/emacs-eat/) (Emulate A Terminal) as a terminal emulator. If Eat prints ["garbled" text](https://elpa.nongnu.org/nongnu-devel/doc/eat.html#Garbled-Text), run `M-x eat-compile-terminfo`, then restart the Eat buffer.

Aside from starting the terminal emulator with `M-x eat` and `M-x eat-project`, Eat adds terminal emulation to Eshell with `eat-eshell-mode`. This allows Eshell to run full screen terminal applications.

```emacs-lisp
(eat-eshell-mode 1)
```

Because Eat now handles full screen terminal applications, Eshell no longer has to run programs in a term buffer. Therefor, the `eshell-visual-commands` list can be unset.

```emacs-lisp
(setq eshell-visual-commands nil)
```

Now, an application like `top` will run in the Eshell buffer without a separate term buffer having to be opened.


<a id="org22d649e"></a>

### History

[Atuin](https://atuin.sh) is a cross-shell utility that stores shell history in a SQLite database. The [eshell-atuin](https://sqrtminusone.xyz/packages/eshell-atuin/) package adds support for both reading from and writing to the history from Eshell.

```emacs-lisp
(eshell-atuin-mode)
```

To read the history in Eshell, bind the `<up>` key to `eshell-atuin-history`, which opens the shell history in the minibuffer. Also unset the `<down>` key, which was bound to `eshell-next-input` for cycling through history in reverse:

```emacs-lisp
(keymap-set eshell-hist-mode-map "<up>" 'eshell-atuin-history)
(keymap-unset eshell-hist-mode-map "<down>")
```

By default, eshell-atuin only shows commands that completed succesfully. To show all commands, change the `eshell-atuin-search-options` variable from `("--exit" "0")` to `nil`:

```emacs-lisp
(setq eshell-atuin-search-options nil)
```

Shell history completion is different from other kinds of completion for two reasons:

1.  Other completion options are presented in a list from top to bottom, with the search prompt at the top. Because `eshell-atuin-history` is opened by pressing the `<up>` key and history is searched backward, the list is reversed by using `vertico-reverse`.

2.  The command history shouldn't be ordered, as that's already handled by Atuin. Instead of ordering the list again, pass `identity` as the `vertico-sort-function`.

Using `vertico-multiform`, which is enabled through `vertico-multiform-mode`, set the above options specifically for the `eshell-atuin-history` function:

```emacs-lisp
(vertico-multiform-mode 1)
(setq vertico-multiform-commands
      '((eshell-atuin-history
	 reverse
	 (vertico-sort-function . identity))))
```


<a id="orga456606"></a>

## Dired

```emacs-lisp
(dirvish-override-dired-mode)
```


<a id="orgce2a837"></a>

## Org


<a id="org202efa9"></a>

### Note-taking

I'm trying out [org-node](https://github.com/meedstrom/org-node), a just-released alternative to [org-roam](https://www.orgroam.com), my current note-taking solution. Currently, this configuration uses both packages.


#### Org-node

Org-node is not on any of the package repositories [yet](https://www.reddit.com/r/emacs/comments/1cfbgqi/comment/l1ok712/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button). This configuration doesn't ensure the package is there, so it's assumed it's installed manually. I've installed org-node through `package-vc-install` for now.

Enable org-node by calling `org-node-enable` whenever an `org-mode` is enabled:

```emacs-lisp
(add-hook 'org-mode-hook #'org-node-enable))
```


#### Org-roam

Org-roam stores notes in `org-roam-directory`, which is `~/org-roam` by default. Use `~/notes` instead:

```emacs-lisp
(setq org-roam-directory (file-truename "~/notes"))
```


#### Org-roam-ui

[Org-roam-ui](https://github.com/org-roam/org-roam-ui) is a graphical frontend for Org-roam, which displays all nodes in a graph for browsing the directory of nodes and discovering possible missing links.


<a id="org7090598"></a>

### Task management

[Beorg](https://beorgapp.com) is an iOS app that takes Org mode to iOS. It includes a list of tasks named *inbox* that's synced via iCloud, meaning it can be added to the agenda through `org-agenda-files`.

```emacs-lisp
(setq org-agenda-files '("/Users/jeff/Library/Mobile\ Documents/iCloud\~com\~appsonthemove\~beorg/Documents/org/inbox.org"))
```


<a id="orgfa7a867"></a>

### Modern defaults for Org exports

Org files can be can be exported to other formats, like HTML. Due to backwards compatibility constraints, however, the produced documents have an `xhtml-strict` doctype with syntax to match. Luckily, Org's exporters are endlessly configurable, and include support for more modern configurations.


#### Smart quotes

Automatically convert single and double quotes to their curly equivalents, depending on the document language.

```emacs-lisp
(setq org-export-with-smart-quotes t)
```


#### Entities

Disable entities, like using `&ldquo;` instead of “ in HTML. This option only works for entities included in the document, not the entities added through smart quotes.

```emacs-lisp
(setq org-export-with-entities nil)
```


#### Headline levels

Instead of 3, set the maximum headline level to 5. This matches the HTML standard of having six headline levels, when counting the document title as the first, leaving five.

```emacs-lisp
(setq org-export-headline-levels 5)
```


#### Table of contents and section numbers

Disable both the table of contents and section numbers, as they're easily turned on when needed, not needed for most exports, and not present in the source documents.

```emacs-lisp
(setq
 org-export-with-toc nil
 org-export-section-numbers nil)
```


#### HTML 5

Aside from replacing the doctype in the document, setting `org-html-doctype` to *html5* has modernizing effects on the output file. For example, it uses the `charset` attribute (as opposed to `http-equiv`) to set the character set, it drops the XML declaration from the header of the document, it switches to the HTML5 validator for the footer (which is then disabled later), and disables HTML table attributes<sup><a id="fnr.2" class="footref" href="#fn.2" role="doc-backlink">2</a></sup>. Setting the doctype instantly transports the document from the start of the millenium to last decade.

To enable the HTML5 doctype , set the `org-html-doctype` variable:

```emacs-lisp
(setq org-html-doctype "html5")
```


#### "Fancy" HTML tags

To continue modernizing, enable `org-html-html5-fancy` for *fancy* HTML5 elements. This means `<figure>` tags to wrap images, a `<header>` tag around the file's main headline, and a `<nav>` tag around the table of contents. It also enables HTML5-powered special blocks to produce modern HTML elements from Org's special blocks:

```org
#+begin_aside
  An aside.
#+end_aside
```

Exports to:

```html
<aside>
  An aside.
</aside>
```

To enable HTML5 "fancy" tags, set the `org-html-html5-fancy` variable:

```emacs-lisp
(setq org-html-html5-fancy t)
```


#### Containers

Aside from the modern elements already enabled by the HTML5 doctype and `org-html-html5-fancy`, Org allows for more customizations to its HTML exports. Use `org-html-container-element` and `org-html-divs` to replace some of the standard `<div>` elements with HTML 5 alternatives:

1.  Use the `<section>` element instead of the main section `<div>` elements
2.  Use the `<header>` element to wrap document preambles
3.  Use the `<main>` element to wrap the document's main section
4.  Use the `<footer>` element to wrap document postambles

```emacs-lisp
(setq
 org-html-container-element "section"
 org-html-divs '((preamble  "header" "preamble")
		(content   "main" "content")
		(postamble "footer" "postamble")))
```


#### Summary

To configure Org mode's HTML exporter to output HTML 5 with modern elements, set the following configuration.

```emacs-lisp
(setq
 org-export-with-smart-quotes t
 org-export-with-entities nil
 org-export-headline-levels 5
 org-export-with-toc nil
 org-export-section-numbers nil
 org-html-doctype "html5"
 org-html-html5-fancy t
 org-html-container-element "section"
 org-html-divs '((preamble  "header" "preamble")
		(content   "main" "content")
		(postamble "footer" "postamble")))
```

When using `use-package` for configuration, hook into the `ox-org` package an use the `:custom` keyword.

```emacs-lisp
(use-package ox-org
  :custom
  org-export-with-smart-quotes t
  org-export-with-entities nil
  org-export-headline-levels 5
  org-export-with-toc nil
  org-export-section-numbers nil
  org-html-doctype "html5"
  org-html-html5-fancy t
  org-html-container-element "section"
  org-html-divs '((preamble  "header" "preamble")
		(content   "main" "content")
		(postamble "footer" "postamble")))
```


<a id="org4524681"></a>

### Source code

One of Org's most impressive features is source code evalutation through its [Library of Babel](https://orgmode.org/worg/org-contrib/babel/). Babel can both evaluate (run a source code block from within an Org document) and extract (take a source code block from an Org document and place it in another file) code.


#### Evaluation

By default, Org only evaluates Emacs Lisp code, but other languages can be added via `org-babel-load-languages`:

```emacs-lisp
(setq
 org-babel-load-languages '((emacs-lisp . t)
			     (shell . t)))
```


#### Extraction

Org extracts each code block that has a "tangle" attribute whenever the `org-babel-tangle` function is evaluated. It's bound do `C-c C-v t` by default. However, it's convenient to have code blocks *tangled* automatically when the source document is saved.

Automatic source code tangling can be enabled per-document by adding a document header line:

```org
# -*- eval: (add-hook 'after-save-hook #'org-babel-tangle nil t); -*-
```

For documents where this header can't be added, or situations where the header hasn't been added yet, there's a package named [org-auto-tangle](https://github.com/yilkalargaw/org-auto-tangle).

```emacs-lisp
(add-hook 'org-mode-hook #'org-auto-tangle-mode)
```

The org-auto-tangle package automatically extracts code blocks for every document that has the `#+auto_tangle: t` option. To turn it on for all Org documents regardless, set `org-auto-tangle-default`:

```emacs-lisp
(setq org-auto-tangle-default t)
```


<a id="org0863a90"></a>

## Email

Use [notmuch.el](https://notmuchmail.org/notmuch-emacs/) to read email.


<a id="org4e9f42d"></a>

## Enhancements

This section covers general enhancements to Emacs which don't warrant their own section.


<a id="org3ec9d5c"></a>

### Backups

Emacs automatically generates [backups](https://www.gnu.org/software/emacs/manual/html_node/emacs/Backup.html) for files not stored in version control. Instead of storing them in the files' directories, put everything in `~/.emacs.d/backups`:

```emacs-lisp
(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))
```


<a id="org292d6a2"></a>

### Key suggestions

With [which-key](https://github.com/justbur/emacs-which-key), Emacs shows suggestions when pausing during an incomplete keypress, which is especially useful when trying to learn Emacs' key bindings. By default, Emacs only shows the already-typed portion of the command, which doesn't help to find the next key to press.

```emacs-lisp
(which-key-mode 1)
```


<a id="org9654aa4"></a>

### Projects

By default, `project.el` only takes projects into account that have a `.git` directory. Use [project-x](https://github.com/karthink/project-x) to allow for projects that are not under version control, and projects nested within other projects.

Project-x is not on any of the pacakge managers, so this configuration assumes it's installed manually for now. Also, this configuration re-sets `project-find-functions` to try `project-x-try-local` before `project-try-vc` to make it work for projects nested within directories under version control.

```emacs-lisp
(project-x-mode 1)
(setq project-find-functions '(project-x-try-local project-try-vc))
```

With project-x enabled, Emacs will recognise directories with a `.project` file as project directories.<sup><a id="fnr.3" class="footref" href="#fn.3" role="doc-backlink">3</a></sup>


<a id="orgd730eb5"></a>

### Precise scrolling

[Added in Emacs 29](https://www.gnu.org/software/emacs/manual///html_node/efaq/New-in-Emacs-29.html), `pixel-scroll-precision-mode` enables smooth scrolling instead of scrolling line by line.

```emacs-lisp
(pixel-scroll-precision-mode 1)
```


<a id="org290e677"></a>

### Indentation

Don't use tabs for indentation.

```emacs-lisp
(indent-tabs-mode 0)
```


<a id="orgf5ab2d5"></a>

## Benchmarking

Use [benchmark-init](https://github.com/dholm/benchmark-init-el) to benchmark Emacs' initialization. Enable benchmark-init at the top of the configuration file, before any packages are loaded.

```emacs-lisp
(use-package benchmark-init
  :ensure t
  :config
  (add-hook 'after-init-hook 'benchmark-init/deactivate))
```

After starting Emacs, the benchmarking results can be examined using the `benchmark-init/show-durations-tree` function. Aside from that, append the total duration to a file named `~/.emacs.d/benchmark.csv` for future reference.

```emacs-lisp
(write-region
 (format "%s,%s\n"
	 (string-trim (shell-command-to-string "git --git-dir ~/emacs-config/.git rev-parse HEAD"))
	 (benchmark-init/node-duration-adjusted benchmark-init/durations-tree))
 nil
 "~/.emacs.d/benchmark.csv"
 'append)
```

## Footnotes

<sup><a id="fn.1" class="footnum" href="#fnr.1">1</a></sup> I'd rather not worry about installing major modes and use a package like [vim-polyglot](https://github.com/sheerun/vim-polyglot), but I haven't been able to find an equivalent for Emacs.

<sup><a id="fn.2" class="footnum" href="#fnr.2">2</a></sup> The easiest way to find out what each of these options does is to locate where the predicate functions are called in [`ox-html.el`](https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/ox-html.el) in Org's source code. For example, to find out what changing the doctype to HTML5 does, search for `org-html-html5-p`.

<sup><a id="fn.3" class="footnum" href="#fnr.3">3</a></sup> Apparently, [`project.el` now supports identifying projects based on a special file in its directory root](https://github.com/karthink/project-x/issues/5#issuecomment-1522535927). Project-x should be obsolete for this purpose, but I haven't figured it out yet.
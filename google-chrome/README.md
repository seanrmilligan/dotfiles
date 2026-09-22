# Google Chrome

## Synchronizing extensions and progressive web apps

Chrome enterprise is actually just regular Chrome, where a policy file has been
placed in a well-known location. Policy files are placed in the following:

- `/etc/opt/google/chrome/policies/managed/`
- `/etc/opt/google/chrome/policies/recommended/`

Viewing loaded policies in Chrome:

```
chrome://policy
```

View installed apps in Chrome:

```
chrome://apps
```
## Configuring `lxqt-panel` to give PWAs their own icon and taskbar slot

In Lubuntu, the taskbar (`lxqt-panel`) allows you to toggle a setting where app
instances can be grouped under one icon or each have their own space on the
taskbar.

How this works involves a mix of the Google Chrome-created `.desktop` file, X11
window manager, and Lubuntu's `lxqt-panel` behavior.

### Chrome `.desktop` entries (on Linux)

Chrome creates `.desktop` files to launch installed PWAs. It installs them in
two locations:

- `~/Desktop/` - for user convenience
- ` ~/.local/share/applications/` - so they can be picked up by the start menu

The `.desktop` file names will have the shape `chrome-{appId}-Default.desktop`.

Inside will look like:

```ini
[Desktop Entry]
Version=1.0
Terminal=false
Type=Application
Name=Gmail
Exec=/opt/google/chrome/google-chrome --profile-directory=Default --app-id=fmgjjmmmlfnkbppncabfkddbjimcfncm
Icon=chrome-fmgjjmmmlfnkbppncabfkddbjimcfncm-Default
StartupWMClass=crx_fmgjjmmmlfnkbppncabfkddbjimcfncm
```

Where, in the case of Gmail, `fmgjjmmmlfnkbppncabfkddbjimcfncm` is the App Id
that Chrome generates for that PWA.

Upon executing, a window will open with `Google-chrome` as the `class`, and
`crx_{appId}` as the `instance`. Together, this forms what is known as the
`WM_CLASS`.

#### The `StartupWMClass` key

`StartupWMClass` is an optional key in a `.desktop` file.

According to the Desktop Entry Specification, the `StartupWMClass` should be
"known that the application will map at least one window with the given string
as its WM class or WM name hint."

Chrome creates this key with the PWA's app ID (`crx_{appId}`).

### X11, `lxqt-panel` (the taskbar), and window grouping

When grouping is turned on, grouping behavior is based on the X11 `WM_CLASS`
property.

`WM_CLASS` contains two null terminated strings:

| `WM_CLASS`                                                    | instance                             | class                 | Application       |
|---------------------------------------------------------------|--------------------------------------|-----------------------|-------------------|
| google-chrome<NULL>Google-chrome<NULL>                        | google-chrome                        | Google-chrome         | Google Chrome     |
| crx_cinhimbnkkaeohfgghhklpknlkffjgod<NULL>Google-chrome<NULL> | crx_cinhimbnkkaeohfgghhklpknlkffjgod | Google-chrome         | YouTube Music PWA |
| crx_fmgjjmmmlfnkbppncabfkddbjimcfncm<NULL>Google-chrome<NULL> | crx_fmgjjmmmlfnkbppncabfkddbjimcfncm | Google-chrome         | Gmail PWA         |
| ghostty<NULL>com.mitchellh.ghostty<NULL>                      | ghostty                              | com.mitchellh.ghostty | Ghostty           |
| sublime_text<NULL>Sublime_text<NULL>                          | sublime_text                         | Sublime_text          | Sublime Text      |

The `class` can be thought of as the overarching type of an application, while
the `instance` is a specific window of that application. So in the table above,
the Gmail PWA "application" is actually an instance of the Google Chrome
application.

When grouping, `lxqt-panel` uses the `class`, not the `instance`, so although
the Chrome-generated app ID is used as the `instance`, all PWAs get stacked
under the `Google-chrome` application instead of as their own separate apps on
the taskbar.

In order to get the PWAs to appear in their own slot on the taskbar, we need to
change their `class` to something other than `Google-chrome`. We accomplish this
with a tool that changes their `class` to _also_ be their Chrome-generated app
ID. So the `WM_CLASS` for Gmail will read:

```text
crx_fmgjjmmmlfnkbppncabfkddbjimcfncm<NULL>crx_fmgjjmmmlfnkbppncabfkddbjimcfncm<NULL>
```

The command that does this is

```shell
$ pwa window-class fix
```

### Restarting the panel

After patching the apps

```shell
pkill -f lxqt-panel; lxqt-panel &
```

## Where the Chrome PWA app ID is found and used

- chrome://apps (right click, App info)
- `.desktop` file name: `chrome-{appId}-Default.desktop`
- `~/.config/google-chrome/Default/Web Applications/Manifest Resources/{appId}/`


## Viewing the X11 Window Properties

This emulates `wmctrl -l -x` but with headers and tabular formatting.

```sh
(echo "ID|DESK|INSTANCE|CLASS|HOST|TITLE"
    xprop -root _NET_CLIENT_LIST | grep -oP '0x\S+' | while read id; do
      props=$(xprop -id "$id" WM_CLASS WM_CLIENT_MACHINE _NET_WM_NAME _NET_WM_DESKTOP 2>/dev/null)
      desk=$(echo "$props" | awk '/_NET_WM_DESKTOP/{print $NF}')
      inst=$(echo "$props" | sed -n '/WM_CLASS/{s/.*= "\([^"]*\)".*/\1/p}')
      cls=$(echo "$props" | sed -n '/WM_CLASS/{s/.*, "\([^"]*\)".*/\1/p}')
      host=$(echo "$props" | sed -n '/WM_CLIENT_MACHINE/{s/.*= "\([^"]*\)".*/\1/p}')
      title=$(echo "$props" | sed -n '/_NET_WM_NAME/{s/^[^"]*"//;s/"$//p}')
      printf "%s|%s|%s|%s|%s|%s\n" "$id" "$desk" "$inst" "$cls" "$host" "$title"
    done) | column -t -s'|'
```

Columns:
- `ID` - X11 Window ID
- `DESK` - Virtual desktop (workspace) number. (Nothing to do with monitor ID)
  - -1 (or 4294967295) represents all workspaces, so the application is open and
    visible on all virtual desktops.
- `INSTANCE` - per-instance identifier of an application
- `CLASS` - the overarching type of the application (such as the program binary)
- `HOST` - Generally the name of the local machine, but will differ for programs
  ran over `ssh -X`.
- `TITLE` - the text of the title bar


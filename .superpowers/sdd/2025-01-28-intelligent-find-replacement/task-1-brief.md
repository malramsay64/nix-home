# Task 1 Brief: Verify and Update Dependencies in pi.nix

**Where this fits:** Initial setup task. Adds fd to nix packages and registers the intelligent-find extension in pi settings, enabling all downstream tasks.

**Files:**
- Modify: `pi.nix` (extraPackages section)
- Modify: `pi.nix` (settings.extensions section)

**Interfaces:**
- Consumes: Existing pi.nix structure
- Produces: Updated pi.nix with fd in extraPackages and intelligent-find in extensions list

**Steps:**

1. Check if fd is already in extraPackages — run `grep -n "fd" pi.nix`
   Expected: Either shows `fd` package or no match

2. If fd is not present, add it to the `extraPackages = with pkgs; [` list (around line 15-30). Add this line:
   ```nix
   fd          # <-- ADD THIS LINE
   ```
   Keep the format consistent with existing entries (one package per line)

3. Add intelligent-find extension to settings.extensions (around line 50-55). Update the extensions list to:
   ```nix
   extensions = [
     "extensions/permission-gate.ts"
     "extensions/intelligent-find.ts"  # <-- ADD THIS LINE
   ];
   ```

4. Rebuild home-manager: `home-manager switch --flake .`
   Expected: No errors, fd and new extension configuration applied

5. Verify fd is available on PATH: `which fd`
   Expected: Output like `/nix/store/.../bin/fd`

6. Commit the changes:
   ```bash
   jj commit -m "feat: add fd package and intelligent-find extension to pi.nix"
   ```

**Global Constraints:**
- Must use ripgrep and fd as managed by pi.nix extraPackages
- No breaking changes to existing configuration

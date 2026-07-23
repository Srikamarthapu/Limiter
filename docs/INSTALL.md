# Install, verify, and uninstall

## Install a GitHub release

1. Download the DMG and matching `.sha256` file from the same GitHub release.
2. Optionally verify the checksum in Terminal:

   ```bash
   shasum -a 256 -c Limiter-0.1.0.dmg.sha256
   ```

3. Open the DMG and drag Limiter into Applications.
4. Control-click `/Applications/Limiter.app`, choose **Open**, and confirm the warning.
5. Complete onboarding.
6. If desired, enable **Open Limiter at login**. macOS may require approval under System Settings → General → Login Items.

The Control-click step is needed because the free side-project release is ad-hoc signed rather than Developer ID notarized. Limiter does not ask you to disable Gatekeeper or run a blanket `xattr` command.

## Uninstall safely

1. Open Limiter and resume protection if it is paused.
2. Turn off **Open Limiter at login** in Settings.
3. Choose **Quit Limiter…** and complete the short pause.
4. Move `/Applications/Limiter.app` to Trash.

To remove local rules and history before uninstalling, use Settings → **Delete all local data…**. Removing the app alone may leave `~/Library/Application Support/Limiter` and the `com.srikamarthapu.Limiter` preferences in your user Library.

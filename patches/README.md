# patches/

## ksu-susfs-v105.patch
SUSFS integration for the **KernelSU v1.0.5 kernel-side tree** (`tiann/KernelSU` tag
`v1.0.5` = `61c0f7f849aaca299fb42516bc8fc516cefe0d59`), applied inside
`drivers/kernelsu` by the CI workflow.

Provenance: derived from `infectedmushi/susfs4ksu` branch `gki-android12-5.10`
(commit `1833d53211478a9e44f89eb50785018051e0bd8a`), file
`kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch`, with mechanical renames
of fork-era `ksu_*` symbols back to v1.0.5 names (`access_ok`, `escape_to_root`,
`try_umount`, `is_zygote`, `is_manager`, `handle_sepolicy`, `setup_selinux`,
`setenforce`, `getenforce`, `is_ksu_domain`, `is_manager_apk`, `apply_kernelsu_rules`,
`kernelsu_init/exit`, `on_post_fs_data`, `track_throne`) and hand-merged
`core_hook.c` hunks (susfs extern block + setuid umount tail). Verified: applies
clean to pristine v1.0.5; all `susfs_*` references resolve against the kernel-side
susfs patch + headers.

Kernel-side SUSFS (fs/, include/, arch hooks) comes directly from the same
susfs4ksu branch at the pinned commit — fetched and applied by the workflow.

Fix vs upstream (2026-09-10, run #32 postmortem): dropped the patch's `access_ok`
extern/definition shim — on arm64 5.10 `access_ok` is a macro (`__range_ok`) and the
shim broke the build once susfs headers pulled `<linux/uaccess.h>` earlier. All susfs
`access_ok` call sites live in core_hook.c which already includes uaccess.h, so the
macro resolves natively.

Fix #2 (run #33 postmortem, LTO link): fs/susfs.c expects the fork's global
`ksu_try_umount(const char*, bool, int)` — v1.0.5's `try_umount` was static in
core_hook.c. Now exported as global `ksu_try_umount` (13 call sites migrated),
and manager.h keeps pristine `is_manager` with a `ksu_is_manager` alias for the
susfs hunks. sus_su.c's `ksu_escape_to_root` ref is dormant (SUS_SU=n).

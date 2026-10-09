"""几个子代理在同一个项目目录里并行做武器时用的简单文件锁(用户 2026-10-09：三批一组派给不同的子代理)。

lock("author") 期间别的进程拿不到同名的锁，会等(默认最多 10 分钟)。锁 = out/.lock_<name> 目录(mkdir 是原子的)；
持有锁的进程被强杀留下的锁，15 分钟后当作过期清掉。bash 那边的同一套在 tools/build_lock.sh。
"""
import contextlib
import os
import time

_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "out")
_STALE = 15 * 60


@contextlib.contextmanager
def lock(name, timeout=600):
    os.makedirs(_ROOT, exist_ok=True)
    path = os.path.join(_ROOT, ".lock_" + name)
    if os.environ.get("VOXEL_LOCK_" + name.upper()) == "1":
        yield                       # 已经在同名锁里(嵌套调用)
        return
    t0 = time.time()
    while True:
        try:
            os.mkdir(path)
            break
        except FileExistsError:
            try:
                if time.time() - os.path.getmtime(path) > _STALE:
                    os.rmdir(path)
                    continue
            except OSError:
                pass
            if time.time() - t0 > timeout:
                raise TimeoutError("lock %s held too long (%s)" % (name, path))
            time.sleep(0.5)
    os.environ["VOXEL_LOCK_" + name.upper()] = "1"
    try:
        yield
    finally:
        os.environ.pop("VOXEL_LOCK_" + name.upper(), None)
        try:
            os.rmdir(path)
        except OSError:
            pass

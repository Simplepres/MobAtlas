## Development

The repository includes addon Lua files, generators, tests and the source snapshots used for this build. Source history is separate from personal SavedVariables.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python tests/run_mobatlas.py
.venv/bin/python tests/check_mobatlas_catalog.py
.venv/bin/python tests/check_mobatlas_data.py
.venv/bin/python tests/check_mobatlas_atlas.py
.venv/bin/python tests/check_mobatlas_preparation.py
.venv/bin/python tests/check_mobatlas_locale.py
.venv/bin/python tests/check_mobatlas_combat.py
.venv/bin/python tests/check_mobatlas_dungeon_pins.py
.venv/bin/python tests/check_mobatlas_rares.py
```

Build an installable ZIP with `python3 tools/package.py`. See [development notes](DEVELOPMENT-NOTES.ru.md) for data generation history and known limitations. Network refreshes are optional and may be rate-limited; offline snapshots are retained when an update fails validation.


Rare reference data: `.venv/bin/python build_mobatlas_rares.py`. Procedural habitat texture: `.venv/bin/python generate_spawn_glow.py`.

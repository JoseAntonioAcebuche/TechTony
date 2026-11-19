import os
import sys
import json
import uuid
import queue
import shutil
import logging
import threading
import platform
import subprocess
from pathlib import Path
from datetime import datetime
import tkinter as tk
from tkinter import filedialog, ttk, messagebox


APP_NAME = "FileArranger"


def get_app_data_dir():
    """Get folder where logs and undo data are saved (AppData on Windows, .local on Linux)."""
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA") or str(Path.home() / "AppData" / "Local")
    else:
        base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    path = Path(base) / APP_NAME
    path.mkdir(parents=True, exist_ok=True)
    return path


APP_DATA_DIR = get_app_data_dir()
LOG_FILE = APP_DATA_DIR / "file_arranger.log"
STATE_FILE = APP_DATA_DIR / "last_operation.json"
BACKUP_ROOT = APP_DATA_DIR / "backups"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(APP_NAME)


CATEGORIES = {
    "Images": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico", ".heic"],
    "Documents": [".pdf", ".doc", ".docx", ".txt", ".rtf", ".odt", ".xls", ".xlsx", ".ppt", ".pptx", ".csv"],
    "Videos": [".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm"],
    "Audio": [".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a"],
    "Archives": [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2"],
    "Code": [".py", ".js", ".html", ".css", ".java", ".cpp", ".c", ".php", ".json", ".xml"],
}


def get_category(filename):
    """Return category name (Images, Documents, etc.) based on file extension."""
    extension = Path(filename).suffix.lower()
    for category, extensions in CATEGORIES.items():
        if extension in extensions:
            return category
    return "Others"


def get_date_folder(filepath, mode):
    """Return date folder name: YYYY-MM (month), YYYY-MM-DD (day), or None."""
    if mode == "none":
        return None
    try:
        modified = datetime.fromtimestamp(os.path.getmtime(filepath))
        return modified.strftime("%Y-%m") if mode == "month" else modified.strftime("%Y-%m-%d")
    except OSError:
        return "Unknown"


def load_last_operation():
    """Load the last arrange operation from JSON (for reverse)."""
    try:
        with STATE_FILE.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
        return data if isinstance(data, dict) and isinstance(data.get("moves"), list) else None
    except (OSError, json.JSONDecodeError):
        return None


def save_last_operation(operation):
    """Save the current operation to JSON so it can be reversed later."""
    temporary = STATE_FILE.with_suffix(".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(operation, handle, indent=2, ensure_ascii=False)
    os.replace(temporary, STATE_FILE)


def clear_last_operation():
    """Delete the saved operation after successful reverse."""
    try:
        STATE_FILE.unlink(missing_ok=True)
    except OSError:
        logger.exception("Could not clear operation history")


def is_within(path, parent):
    """Check if path is inside parent folder (to avoid scanning destination)."""
    try:
        Path(path).resolve().relative_to(Path(parent).resolve())
        return True
    except (ValueError, OSError):
        return False


def _norm(path):
    """Resolve a path and normalise case (Windows is case-insensitive)."""
    return os.path.normcase(str(Path(path).resolve()))


def _build_protected_lists():
    """Return (exact, tree). exact = blocked only as the folder itself; tree = blocked with everything inside."""
    exact, tree = set(), set()
    home = Path.home()

    if os.name == "nt":
        drive = os.environ.get("SystemDrive", "C:") + "\\"
        for var in ("SystemRoot", "windir", "ProgramFiles", "ProgramFiles(x86)", "ProgramW6432", "ProgramData"):
            value = os.environ.get(var)
            if value:
                tree.add(_norm(value))
        for name in ("Recovery", "$Recycle.Bin", "System Volume Information", "Boot", "Windows", "PerfLogs"):
            tree.add(_norm(Path(drive) / name))
        tree.add(_norm(home / "AppData"))
        tree.add(_norm(Path(drive) / "Users" / "Default"))
        tree.add(_norm(Path(drive) / "Users" / "All Users"))
        exact.add(_norm(Path(drive) / "Users"))
    else:
        for name in (
            "/root", "/bin", "/sbin", "/boot", "/dev", "/etc", "/lib", "/lib32", "/lib64", "/proc",
            "/run", "/sys", "/usr", "/var", "/opt", "/snap", "/srv",
            "/System", "/Library", "/Applications", "/private",
        ):
            tree.add(_norm(name))
        for name in ("/", "/home", "/Users", "/mnt", "/media"):
            exact.add(_norm(name))

    # The user's own top-level profile folder (not the folders inside it, like Downloads)
    exact.add(_norm(home))
    return exact, tree


PROTECTED_EXACT, PROTECTED_TREE = _build_protected_lists()


def restricted_reason(path):
    """Return a short reason if the folder is restricted (system/root/home level), else None."""
    try:
        resolved = Path(path).resolve()
    except OSError:
        return "The folder could not be checked."

    if resolved.parent == resolved:
        return "Drive/filesystem root folders cannot be arranged."

    normalized = _norm(resolved)
    if normalized in PROTECTED_EXACT:
        return "This top-level folder is restricted. Choose a folder inside it instead (e.g. Downloads)."

    for protected in PROTECTED_TREE:
        if normalized == protected or normalized.startswith(protected + os.sep):
            return "This is a system/restricted folder and cannot be arranged."

    return None


# Files that programs/the OS depend on. These are never moved.
PROTECTED_EXTENSIONS = {
    ".exe", ".dll", ".sys", ".lnk", ".bat", ".cmd", ".ini", ".msi", ".drv", ".ocx", ".cpl",
    ".scr", ".com", ".reg", ".inf", ".cat", ".so", ".dylib", ".app", ".desktop", ".service",
}

# Folders that mean "this is a project/app, don't touch it".
PROJECT_FOLDER_NAMES = {
    ".git", ".svn", ".hg", "node_modules", "venv", ".venv", "env", "__pycache__",
    ".idea", ".vscode", "site-packages",
}
PROJECT_MARKER_FILES = {
    "package.json", "pyproject.toml", "requirements.txt", "setup.py", "pom.xml", "build.gradle",
    "cargo.toml", "composer.json", "go.mod", "gemfile", "makefile", "cmakelists.txt", "dockerfile",
    "manage.py", "web.config",
}
PROJECT_MARKER_SUFFIXES = (".sln", ".csproj", ".vcxproj", ".xcodeproj", ".uproject")


def is_hidden_or_system(file_path, filename):
    """True for dotfiles on any OS, and hidden/system-flagged files on Windows."""
    if filename.startswith("."):
        return True
    if os.name == "nt":
        try:
            attributes = os.stat(file_path).st_file_attributes
            # 0x2 = hidden, 0x4 = system
            return bool(attributes & 0x2 or attributes & 0x4)
        except (OSError, AttributeError):
            return False
    return False


def project_marker(folder):
    """Return the name of a project marker found directly inside folder, else None."""
    try:
        with os.scandir(folder) as entries:
            for entry in entries:
                name = entry.name.lower()
                if entry.is_dir(follow_symlinks=False) and name in PROJECT_FOLDER_NAMES:
                    return entry.name
                if entry.is_file(follow_symlinks=False) and (
                    name in PROJECT_MARKER_FILES or name.endswith(PROJECT_MARKER_SUFFIXES)
                ):
                    return entry.name
    except OSError:
        return None
    return None


def collect_files(source, destination, same_folder):
    """Get files to arrange. Returns (files, stats).

    Skips: category folders, the destination, restricted/system folders, project folders,
    program/system files (.exe, .dll, ...) and hidden/system files.
    """
    source_path = Path(source).resolve()
    destination_path = Path(destination).resolve() if destination else source_path
    category_names = set(CATEGORIES) | {"Others"}
    collected = []
    stats = {"protected_files": 0, "hidden_files": 0, "project_folders": []}
    internal_files = {LOG_FILE.resolve(), STATE_FILE.resolve()}

    for current, directories, filenames in os.walk(source_path, topdown=True, followlinks=False):
        current_path = Path(current).resolve()

        kept_directories = []
        for directory in directories:
            child = (current_path / directory).resolve()

            # Skip category folders when arranging in same folder
            if same_folder and directory in category_names and current_path == source_path:
                continue

            # Never walk into restricted/system folders
            if restricted_reason(child):
                continue

            # Skip project/app folders (git repos, node_modules, venvs, solutions, ...)
            if directory.lower() in PROJECT_FOLDER_NAMES or project_marker(child):
                stats["project_folders"].append(str(child))
                continue

            # Skip destination if it's inside source
            if child == destination_path or is_within(child, destination_path):
                continue

            kept_directories.append(directory)

        directories[:] = kept_directories

        for filename in filenames:
            file_path = current_path / filename
            try:
                if not file_path.is_file() or file_path.is_symlink():
                    continue
                if file_path.resolve() in internal_files:
                    continue
                if file_path.suffix.lower() in PROTECTED_EXTENSIONS:
                    stats["protected_files"] += 1
                    continue
                if is_hidden_or_system(file_path, filename):
                    stats["hidden_files"] += 1
                    continue
                collected.append(str(file_path))
            except OSError:
                logger.warning("Could not inspect file: %s", file_path)

    return collected, stats


def unique_path(path):
    """If file exists, return path with (1), (2), etc. appended."""
    path = Path(path)
    if not path.exists():
        return path

    number = 1
    while True:
        candidate = path.with_name(f"{path.stem} ({number}){path.suffix}")
        if not candidate.exists():
            return candidate
        number += 1


def open_path(path):
    """Open a file or folder using the system default app."""
    try:
        if platform.system() == "Windows":
            os.startfile(str(path))
        elif platform.system() == "Darwin":
            subprocess.Popen(["open", str(path)])
        else:
            subprocess.Popen(["xdg-open", str(path)])
    except Exception:
        logger.exception("Cannot open path: %s", path)
        messagebox.showerror("Open Error", f"Cannot open:\n{path}")


class FileArrangerApp:
    """Main GUI application."""

    def __init__(self, root):
        self.root = root
        self.root.title("File Arranger")
        self.root.geometry("620x610")
        self.root.minsize(580, 570)

        self.events = queue.Queue()
        self.worker = None
        self.busy = False

        self.source_var = tk.StringVar()
        self.dest_var = tk.StringVar()
        self.same_folder_var = tk.BooleanVar(value=False)
        self.date_var = tk.StringVar(value="month")
        self.conflict_var = tk.StringVar(value="ask")
        self.progress_var = tk.DoubleVar(value=0)

        self._build_ui()
        self._refresh_reverse_button()
        self.root.after(100, self._process_events)
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self):
        """Create all the GUI widgets."""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="How to Use", command=self.show_instructions)
        help_menu.add_command(label="Open Log", command=lambda: open_path(LOG_FILE))
        help_menu.add_separator()
        help_menu.add_command(
            label="About",
            command=lambda: messagebox.showinfo("About", "File Arranger\nCreated by Jose Antonio Acebuche"),
        )

        font_label = ("Segoe UI", 10)

        tk.Label(self.root, text="Source Folder:", font=font_label).pack(anchor="w", padx=20, pady=(12, 0))
        source_frame = tk.Frame(self.root)
        source_frame.pack(fill="x", padx=20)
        tk.Entry(source_frame, textvariable=self.source_var).pack(side="left", fill="x", expand=True, padx=(0, 6))
        tk.Button(source_frame, text="Browse", command=self.browse_source, width=10).pack(side="left")

        tk.Label(self.root, text="Destination Folder:", font=font_label).pack(anchor="w", padx=20, pady=(9, 0))
        dest_frame = tk.Frame(self.root)
        dest_frame.pack(fill="x", padx=20)
        tk.Entry(dest_frame, textvariable=self.dest_var).pack(side="left", fill="x", expand=True, padx=(0, 6))
        tk.Button(dest_frame, text="Browse", command=self.browse_destination, width=10).pack(side="left")

        tk.Label(self.root, text="Leave destination blank when using 'Arrange in same folder'.",
                 font=("Segoe UI", 9), fg="gray").pack(anchor="w", padx=20)

        tk.Checkbutton(self.root, text="Arrange in same folder", variable=self.same_folder_var,
                       font=font_label).pack(anchor="w", padx=20, pady=6)

        tk.Label(self.root, text="Date grouping:", font=font_label).pack(anchor="w", padx=20, pady=(5, 0))
        date_frame = tk.Frame(self.root)
        date_frame.pack(anchor="w", padx=40)
        for label, value in [("Month (2026-11)", "month"), ("Day (2026-11-18)", "day"), ("None", "none")]:
            tk.Radiobutton(date_frame, text=label, variable=self.date_var, value=value, font=font_label).pack(anchor="w")

        tk.Label(self.root, text="When a file with the same name exists:", font=font_label).pack(anchor="w", padx=20, pady=(8, 0))
        conflict_frame = tk.Frame(self.root)
        conflict_frame.pack(anchor="w", padx=40)
        for label, value in [
            ("Ask each time", "ask"),
            ("Replace all (existing files are backed up)", "replace"),
            ("Append all (filename (1).ext)", "append"),
            ("Skip all", "skip"),
        ]:
            tk.Radiobutton(conflict_frame, text=label, variable=self.conflict_var, value=value, font=font_label).pack(anchor="w")

        self.progress = ttk.Progressbar(self.root, variable=self.progress_var, maximum=100, length=560)
        self.progress.pack(padx=20, pady=(14, 6), fill="x")

        self.status_label = tk.Label(self.root, text="Ready", fg="gray", font=font_label)
        self.status_label.pack()

        button_frame = tk.Frame(self.root)
        button_frame.pack(fill="x", padx=20, pady=12)
        self.arrange_button = tk.Button(button_frame, text="Arrange Files", command=self.start_arrange,
                                        bg="#4CAF50", fg="white", font=("Segoe UI", 10, "bold"), height=2)
        self.arrange_button.pack(side="left", fill="x", expand=True, padx=(0, 5))

        self.reverse_button = tk.Button(button_frame, text="Reverse Last", command=self.reverse_last,
                                        bg="#f44336", fg="white", font=("Segoe UI", 10, "bold"), height=2)
        self.reverse_button.pack(side="right", fill="x", expand=True)

        tk.Label(self.root, text=f"Logs and undo data are saved in: {APP_DATA_DIR}",
                 font=("Segoe UI", 8), fg="gray", wraplength=570).pack(padx=15, pady=(0, 8))

    def _refresh_reverse_button(self):
        """Enable Reverse button only if there's a previous operation to undo."""
        self.reverse_button.config(state="normal" if load_last_operation() else "disabled")

    def browse_source(self):
        """Open folder dialog for source."""
        selected = filedialog.askdirectory()
        if selected:
            self.source_var.set(selected)

    def browse_destination(self):
        """Open folder dialog for destination."""
        selected = filedialog.askdirectory()
        if selected:
            self.dest_var.set(selected)

    def show_instructions(self):
        """Show help dialog."""
        messagebox.showinfo(
            "How to Use",
            "FILE ARRANGER\n\n"
            "1. Select a source folder.\n"
            "2. Select a destination folder, unless arranging in the same folder.\n"
            "3. Choose date grouping: Month, Day, or None.\n"
            "4. Choose how filename conflicts should be handled.\n"
            "5. Click Arrange Files.\n\n"
            "Safety: system folders, project folders, program files (.exe/.dll) and hidden files are never moved.\n\n"
            "Reverse Last undoes the most recent completed arrange operation.\n"
            "Existing files replaced by the app are backed up for undo.\n\n"
            "Created by Jose Antonio Acebuche",
        )

    def _validate_inputs(self):
        """Check if source and destination are valid before starting."""
        source = self.source_var.get().strip()
        destination = self.dest_var.get().strip()
        same_folder = self.same_folder_var.get()

        if not source or not os.path.isdir(source):
            messagebox.showerror("Invalid Source", "Please select a valid source folder.")
            return None

        if same_folder:
            destination = source
        elif not destination or not os.path.isdir(destination):
            messagebox.showerror("Invalid Destination", "Please select a valid destination folder.")
            return None

        for label, folder in (("Source", source), ("Destination", destination)):
            reason = restricted_reason(folder)
            if reason:
                messagebox.showerror("Restricted Folder", f"{label} folder is not allowed:\n{folder}\n\n{reason}")
                return None

        marker = project_marker(source)
        if marker:
            messagebox.showerror(
                "Project Folder",
                f"This looks like a project/app folder (found: {marker}).\n\n"
                "Arranging it could break the project. Choose a different folder.",
            )
            return None

        source_real = Path(source).resolve()
        destination_real = Path(destination).resolve()

        if not same_folder and source_real == destination_real:
            messagebox.showerror("Folder Selection", "Source and destination are the same.")
            return None

        if not same_folder and is_within(destination_real, source_real):
            messagebox.showerror("Folder Selection", "Destination cannot be inside the source folder.")
            return None

        return source, destination, same_folder

    def _build_confirm_text(self, files, stats, source, destination, same_folder, date_mode):
        """Build the detailed confirmation message shown before arranging."""
        counts = {}
        for path in files:
            category = get_category(os.path.basename(path))
            counts[category] = counts.get(category, 0) + 1
        breakdown = ", ".join(f"{name}: {count}" for name, count in sorted(counts.items(), key=lambda i: -i[1]))

        target = source if same_folder else destination
        date_text = {"month": "by month", "day": "by day", "none": "no date folders"}.get(date_mode, date_mode)

        lines = [
            "Files will be MOVED out of their current folders.",
            "",
            f"From:  {source}",
            f"To:      {target}",
            f"Layout: Category folders, {date_text}",
            "",
            f"Files to move: {len(files)}",
            breakdown,
            "",
            "Skipped automatically:",
            f"  Program/system files (.exe, .dll, ...): {stats['protected_files']}",
            f"  Hidden files: {stats['hidden_files']}",
            f"  Project folders: {len(stats['project_folders'])}",
            "",
            "Is this the right folder? Continue?",
        ]
        return "\n".join(lines)

    def start_arrange(self):
        """Start the arrange process in a background thread."""
        if self.busy:
            return

        validated = self._validate_inputs()
        if not validated:
            return

        source, destination, same_folder = validated
        date_mode = self.date_var.get()
        conflict_mode = self.conflict_var.get()

        files, stats = collect_files(source, destination, same_folder)
        if not files:
            messagebox.showinfo(
                "No Files",
                "No files to arrange.\n\n"
                f"Skipped program/system files: {stats['protected_files']}\n"
                f"Skipped hidden files: {stats['hidden_files']}\n"
                f"Skipped project folders: {len(stats['project_folders'])}",
            )
            return

        if not messagebox.askyesno("Confirm Arrange", self._build_confirm_text(
            files, stats, source, destination, same_folder, date_mode
        ), icon="warning"):
            return

        self.busy = True
        self.arrange_button.config(state="disabled")
        self.reverse_button.config(state="disabled")
        self.progress_var.set(0)
        self.status_label.config(text="Starting...")

        operation_id = datetime.now().strftime("%Y%m%d_%H%M%S_") + uuid.uuid4().hex[:8]
        self.worker = threading.Thread(
            target=self._arrange_worker,
            args=(operation_id, files, source, destination, same_folder, date_mode, conflict_mode),
            daemon=True,
        )
        self.worker.start()

    def _arrange_worker(self, operation_id, files, source, destination, same_folder, date_mode, conflict_mode):
        """Background thread that actually moves the files."""
        moves = []
        moved = 0
        skipped = 0
        total = len(files)
        backup_dir = BACKUP_ROOT / operation_id

        logger.info("ARRANGE START | %s", operation_id)

        for index, filepath in enumerate(files, start=1):
            filename = os.path.basename(filepath)
            category = get_category(filename)
            base_folder = source if same_folder else destination
            date_folder = get_date_folder(filepath, date_mode)
            destination_folder = Path(base_folder) / category
            if date_folder:
                destination_folder /= date_folder

            try:
                destination_folder.mkdir(parents=True, exist_ok=True)
            except OSError:
                skipped += 1
                self.events.put(("progress", index, total, moved, skipped))
                continue

            destination_path = destination_folder / filename
            backup_path = None

            if destination_path.exists():
                if conflict_mode == "ask":
                    response = threading.Event()
                    answer = {"value": "skip"}
                    self.events.put(("conflict", filename, answer, response))
                    response.wait()
                    action = answer["value"]
                else:
                    action = conflict_mode

                if action == "skip":
                    skipped += 1
                    self.events.put(("progress", index, total, moved, skipped))
                    continue

                if action == "append":
                    destination_path = unique_path(destination_path)

                elif action == "replace":
                    try:
                        backup_dir.mkdir(parents=True, exist_ok=True)
                        backup_path = unique_path(backup_dir / filename)
                        shutil.move(str(destination_path), str(backup_path))
                    except OSError:
                        skipped += 1
                        self.events.put(("progress", index, total, moved, skipped))
                        continue

            try:
                shutil.move(filepath, str(destination_path))
                moves.append({
                    "original": filepath,
                    "destination": str(destination_path),
                    "backup": str(backup_path) if backup_path else None,
                })
                moved += 1
                logger.info("MOVED | %s | %s", filepath, destination_path)
            except Exception:
                logger.exception("Could not move: %s", filepath)
                if backup_path and backup_path.exists() and not destination_path.exists():
                    try:
                        shutil.move(str(backup_path), str(destination_path))
                    except OSError:
                        pass
                skipped += 1

            self.events.put(("progress", index, total, moved, skipped))

        operation = {
            "operation_id": operation_id,
            "created_at": datetime.now().isoformat(timespec="seconds"),
            "source": source,
            "destination": destination,
            "moves": moves,
        }

        if moves:
            try:
                save_last_operation(operation)
            except OSError:
                logger.exception("Could not save undo history.")

        logger.info("ARRANGE END | moved=%d | skipped=%d", moved, skipped)
        self.events.put(("finished", moved, skipped, source if same_folder else destination, bool(moves)))

    def _process_events(self):
        """Update GUI from background thread events (progress, conflicts, finish)."""
        try:
            while True:
                event = self.events.get_nowait()
                event_type = event[0]

                if event_type == "progress":
                    _, current, total, moved, skipped = event
                    self.progress_var.set(current / total * 100 if total else 0)
                    self.status_label.config(text=f"Processing {current}/{total} | Moved: {moved} | Skipped: {skipped}")

                elif event_type == "conflict":
                    _, filename, answer, response = event
                    choice = messagebox.askyesnocancel(
                        "File Exists",
                        f"{filename}\n\nYes = Replace\nNo = Append\nCancel = Skip",
                    )
                    answer["value"] = "replace" if choice is True else "append" if choice is False else "skip"
                    response.set()

                elif event_type == "finished":
                    _, moved, skipped, output_folder, has_moves = event
                    self.busy = False
                    self.arrange_button.config(state="normal")
                    self.status_label.config(text=f"Done! Moved: {moved} | Skipped: {skipped}")
                    self._refresh_reverse_button()
                    messagebox.showinfo("Done", f"Moved: {moved}\nSkipped: {skipped}")
                    if has_moves and messagebox.askyesno("Open Folder", "Open the destination folder?"):
                        open_path(output_folder)

        except queue.Empty:
            pass

        self.root.after(100, self._process_events)

    def reverse_last(self):
        """Undo the last arrange operation using the saved JSON."""
        if self.busy:
            return

        operation = load_last_operation()
        if not operation or not operation.get("moves"):
            messagebox.showinfo("Reverse", "No operation to reverse.")
            self._refresh_reverse_button()
            return

        moves = operation["moves"]
        if not messagebox.askyesno("Reverse", f"Restore {len(moves)} files?"):
            return

        restored = 0
        skipped = 0

        for move in reversed(moves):
            original = Path(move["original"])
            current = Path(move["destination"])
            backup = Path(move["backup"]) if move.get("backup") else None

            try:
                if not current.exists():
                    skipped += 1
                    continue

                original.parent.mkdir(parents=True, exist_ok=True)

                if original.exists():
                    skipped += 1
                    continue

                shutil.move(str(current), str(original))

                if backup and backup.exists() and not current.exists():
                    shutil.move(str(backup), str(current))

                logger.info("REVERSED | %s", original)
                restored += 1

            except Exception:
                logger.exception("Reverse failed: %s", current)
                skipped += 1

        remaining = [m for m in moves if Path(m["destination"]).exists() or (m.get("backup") and Path(m["backup"]).exists())]
        if remaining:
            operation["moves"] = remaining
            save_last_operation(operation)
        else:
            clear_last_operation()

        self.status_label.config(text=f"Reversed: {restored} | Skipped: {skipped}")
        self._refresh_reverse_button()
        messagebox.showinfo("Reverse Done", f"Restored: {restored}\nSkipped: {skipped}")

    def _on_close(self):
        """Prevent closing while operation is running."""
        if self.busy:
            messagebox.showwarning("Busy", "Please wait for the operation to finish.")
            return
        self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk()
    app = FileArrangerApp(root)
    root.mainloop()
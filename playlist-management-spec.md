# 🎵 Playlist Management Features Specification

**Tunes4S Playlist Management Module**

**Date:** November 19, 2025

---

## 📋 **FEATURE DEFINITION**

Playlist management encompasses all operations users can perform on their music collections, including adding, removing, reordering, and saving playlists between sessions.

---

## 🎯 **CORE REQUIREMENTS**

### **1.1 Current Playlist Operations**
**Import Folder** ✅ **(IMPLEMENTED)**
- Select folder via NSOpenPanel
- Recursively scan for MP3 files
- Extract ID3 metadata for each track
- Add all valid songs to playlist

### **1.2 Missing Core Operations**
**Add Individual Songs** ❌ **(TO IMPLEMENT)**
- File picker for individual MP3 selection
- Add to existing playlist (append)
- Insert at specific position
- Batch selection support

**Remove Songs** ❌ **(TO IMPLEMENT)**
- Remove single song
- Remove multiple selection
- Remove all (clear playlist)
- Undo last removal

**Reorder Songs** ❌ **(TO IMPLEMENT)**
- Drag and drop reordering
- Move selection up/down
- Sort by various criteria
- Reverse order

---

## 🔧 **DETAILED FEATURE SPECIFICATION**

### **2.1 Add Songs Interface**

#### **Individual File Addition**
```
UI Element: "Add Song" button (➕ icon)
Location: Playlist view header
Functionality:
- Opens NSOpenPanel with MP3 filter
- Allows multiple file selection
- Auto-scrolls to newly added songs
```

#### **Song Validation**
- Check file format (currently MP3 only)
- Verify file readability
- Extract and validate metadata
- Detect duplicates by file path/hash
- Handle corrupted files gracefully

#### **User Feedback**
- Progress indicator during import
- Count of successfully added files
- List of files that couldn't be added with reasons

### **2.2 Remove Songs Interface**

#### **Single Song Removal**
```
UI Element: Context menu + Delete button per row
Right-click menu:
- Remove from playlist
- Show in Finder
- Copy file path
```

#### **Bulk Removal**
```
UI Selection:
- Shift+Click for contiguous
- Cmd+Click for non-contiguous
- Select All (Cmd+A)
- Invert Selection

Remove Actions:
- Remove Selected (Del key / button)
- Clear All (confirmation dialog)
- Keep Only Selected (invert remove)
```

#### **Safety Features**
- Confirmation dialog for bulk operations
- Undo last removal (Cmd+Z)
- Backup of removed songs in memory

### **2.3 Reorder Interface**

#### **Drag & Drop**
```
Implementation: SwiftUI .onDrag() + .onDrop()
Features:
- Visual drag indicator
- Drop zone highlighting
- Real-time position preview
- Auto-scroll during drag
```

#### **Move Operations**
```
Button Controls:
- Move Up (single or selection)
- Move Down (single or selection)
- Move to Top/Bottom

Sort Options:
- By Title (A-Z, Z-A)
- By Artist (A-Z, Z-A)
- By Album (A-Z, Z-A)
- By File Order
- By Duration
- Random Shuffle
```

---

## 🎨 **UI/UX DESIGN SPECIFICATION**

### **3.1 Playlist Header**
```
Layout: HStack with centered content
Elements:
├── [Playlist Icon] "Playlist" [Count Badge]
├── [Add Song Button] ➕
├── [Remove Button] ➖
├── [Sort Menu] ⇅
└── [More Menu] ⋯
```

### **3.2 Song Row Design**
```
Standard Row Height: 44pt

Layout: HStack with leading alignment
├── [Play Button] ▶ (shows for current/hovered)
├── [Song Info] VStack
│   ├── [Title] "Song Title.mp3" (bold, max 1 line)
│   └── [Artist - Album] "Artist Name - Album Name"
├── [Duration] "3:45" (right aligned, monospaced)
└── [Context Menu Button] ⋯ (hover only)
```

### **3.3 Selection States**
```
Normal State: Gray background (#2a2a2a)
Selected State: Accent color highlight (#ffcc00 with opacity)
Playing State: Green accent (#00ff00)
Hover State: Slight brightness increase
```

---

## 💾 **DATA MANAGEMENT SPECIFICATION**

### **4.1 Song Model** ✅ **(IMPLEMENTED)**
```swift
struct Song: Identifiable, Hashable {
    var id: Int              // Unique identifier
    var title: String        // Display title (from ID3 or filename)
    var album: String        // Album name
    var artist: String       // Artist name
    var file: String         // Absolute file path
    var songImage: AttachedPicture? // Album artwork (if available)
}
```

### **4.2 Playlist Persistence** ❌ **(TO IMPLEMENT)**

#### **Storage Strategy**
```
Format: JSON via UserDefaults (simplicity)
File: ~/Library/Containers/[BundleId]/Data/Library/Preferences/com.yourapp.plist
Key: "saved_playlist_v1"
```

#### **Data Structure**
```json
{
  "version": 1,
  "songs": [
    {
      "id": 1,
      "title": "Song Title",
      "album": "Album Name",
      "artist": "Artist Name",
      "file": "/full/path/to/song.mp3",
      "lastPlayed": "2025-11-19T14:30:00Z"
    }
  ],
  "currentSongIndex": 2,
  "currentPosition": 145.67
}
```

#### **Recovery Handling**
- Graceful handling of missing files
- Path update prompts for moved files
- Automatic cleanup of invalid entries
- Backup of working playlist before saves

---

## 🔄 **INTEGRATION POINTS**

### **5.1 AudioService Integration**
- Notify playback changes when songs reordered
- Stop playback when current song removed
- Adjust current index after insertions/deletions

### **5.2 UI State Synchronization**
- Update now playing when playlist changes
- Maintain selection during reordering
- Preserve scroll position during updates

---

## 🧪 **TESTING SPECIFICATION**

### **6.1 Unit Tests**
- Song model validation
- File path resolution
- Duplicate detection
- Persistence save/load

### **6.2 Integration Tests**
- Add/remove operations
- Reordering persistence
- File validation during import
- Recovery from corrupted saves

### **6.3 User Acceptance Tests**
- Drag & drop song reordering
- Multiple song removal
- Playlist persistence across app restarts
- Error handling for missing files

---

## 📈 **IMPLEMENTATION PRIORITY**

### **Phase 2.A: Core Management (HIGH PRIORITY)**
1. **Add Individual Songs** - File picker integration
2. **Remove Single Song** - Context menu + delete button
3. **Remove Multiple Songs** - Selection system
4. **Drag & Drop Reordering** - SwiftUI gestures

### **Phase 2.B: Advanced Management (MEDIUM PRIORITY)**
1. **Sort Options** - Multiple sorting criteria
2. **Bulk Operations** - Select all, invert selection
3. **Duplicate Detection** - Prevent duplicate songs
4. **Undo/Redo Support** - Basic undo for removals

### **Phase 2.C: Persistence (HIGH PRIORITY)**
1. **Auto-Save** - Save on every playlist change
2. **Auto-Load** - Restore on app launch
3. **Error Recovery** - Handle missing/moved files
4. **Backup System** - Prevent data loss

---

## ⚡ **PERFORMANCE REQUIREMENTS**

- **Large Playlists**: Support 1000+ songs smoothly
- **UI Responsiveness**: Instant feedback for all operations
- **Memory Efficiency**: Lazy loading for metadata-heavy playlists
- **File I/O**: Non-blocking save/load operations

---

## 🛡️ **ERROR HANDLING**

### **File Access Errors**
- Missing file permissions
- File moved or deleted
- Corrupted MP3 metadata
- Insufficient disk space

### **State Integrity**
- Invalid playlist data recovery
- Missing current song handling
- Position out of bounds recovery

### **User Operations**
- Undo failed operations where possible
- Clear error messages with retry options
- Safe fallbacks for destructive operations

---

**Status: Ready for P2.2 Playlist Management implementation**

# QuickCam - Camera Gallery App

A Flutter camera app with cloud storage and automatic photo cleanup.

## Features

- 📸 **Direct Camera Access** - Opens straight to camera
- ☁️ **Cloud Storage** - Photos stored securely in Supabase
- 🗑️ **Auto-Cleanup** - Photos automatically delete after 30 days
- 🖼️ **Gallery Preview** - Floating gallery window while camera is open
- 👤 **No Login Required** - Anonymous authentication

## Screenshots

| Camera Screen | Gallery Preview | Full Gallery |
|---------------|-----------------|--------------|
| <img src="screenshots/camera.jpg" width="200"> | <img src="screenshots/preview.jpg" width="200"> | <img src="screenshots/gallery.jpg" width="200"> |

## Tech Stack

- **Frontend**: Flutter, Dart
- **Backend**: Supabase (PostgreSQL + Storage)
- **Authentication**: Anonymous Auth
- **Camera**: camera package

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/quickcam.git
   cd quickcam
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project
   - Enable Anonymous authentication
   - Create `images` table and storage bucket
   - Update `lib/config.dart` with your credentials

4. **Run the app**
   ```bash
   flutter run
   ```

## Supabase Setup

Run this SQL in your Supabase SQL editor:

```sql
-- Create images table
CREATE TABLE images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days')
);

-- Enable Row Level Security
ALTER TABLE images ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own images" ON images FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own images" ON images FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own images" ON images FOR DELETE USING (auth.uid() = user_id);
```

## Build Release APK

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── screens/
│   ├── camera_screen.dart    # Main camera interface
│   └── gallery_screen.dart   # Full gallery view
├── services/
│   ├── camera_service.dart   # Camera functionality
│   └── supabase_service.dart # Cloud storage & cleanup
├── config.dart              # Supabase configuration
└── main.dart               # App entry point
```

## Features in Detail

### Camera Screen
- Full-screen camera preview
- One-tap photo capture
- Floating gallery preview
- Real-time image counter

### Gallery System
- Grid view of all photos
- Full-screen image preview
- Days remaining indicator
- Manual delete option

### Auto-Cleanup
- Runs on app startup
- Deletes photos older than 30 days
- Removes both database entries and storage files

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the project
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

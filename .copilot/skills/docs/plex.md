### Webhook Payload Example

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

An example of a webhook payload for a 'media.play' event, showcasing the structure of event notifications.

```APIDOC
## Webhook Payload Example

### Description
This is an example of a webhook payload for a `media.play` event. Webhooks can notify your application about various server events.

### Supported Events
- `library.new`: New item added to a library.
- `library.on.deck`: New item added to 'On Deck'.
- `media.play`: Media playback started.
- `media.pause`: Media playback paused.
- `media.resume`: Media playback resumed.
- `media.stop`: Media playback stopped.
- `media.scrobble`: Media item marked as watched.
- `media.rate`: Media item rated.
- `admin.database.backup`: Database backup completed.
- `admin.database.corrupted`: Database corruption detected.
- `device.new`: New device connected to the server.
- `playback.started`: Media transcoding started.

### Request Example
```json
{
  "event": "media.play",
  "user": true,
  "owner": true,
  "Account": {
    "id": 12345678,
    "thumb": "https://plex.tv/users/abc123/avatar",
    "title": "username"
  },
  "Server": {
    "title": "MyPlexServer",
    "uuid": "abc123def456ghi789"
  },
  "Player": {
    "local": true,
    "publicAddress": "203.0.113.42",
    "title": "Living Room TV",
    "uuid": "client-123-456"
  },
  "Metadata": {
    "librarySectionType": "movie",
    "ratingKey": "12345",
    "key": "/library/metadata/12345",
    "parentRatingKey": "12344",
    "grandparentRatingKey": "12343",
    "guid": "plex://movie/5d776b59ad5437001f79c6f8",
    "type": "movie",
    "title": "The Matrix",
    "summary": "A computer hacker learns from mysterious rebels...",
    "year": 1999,
    "thumb": "/library/metadata/12345/thumb/1697123456",
    "art": "/library/metadata/12345/art/1697123456",
    "addedAt": 1697000000,
    "updatedAt": 1697123456
  }
}
```
```

--------------------------------

### Get all Plex server preferences

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Fetches all configurable preferences and settings for the Plex Media Server. This GET request requires authentication via X-Plex-Token and returns a JSON object containing various settings.

```bash
curl -X GET "http://192.168.1.100:32400/:/prefs?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Generate Direct Media Links using Curl

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Demonstrates how to generate direct download or streaming URLs for media files and thumbnails from Plex using curl commands. These examples show how to get full file downloads, stream directly, and retrieve various image types.

```bash
# Get media part download URL
curl -X GET "http://192.168.1.100:32400/library/parts/111213/1697000000/file.mkv?download=1&X-Plex-Token=$PLEX_TOKEN"

# This returns the file as a download with proper headers
# For streaming without download prompt:
curl -X GET "http://192.168.1.100:32400/library/parts/111213/1697000000/file.mkv?X-Plex-Token=$PLEX_TOKEN"

# Get thumbnail/poster URL
curl -X GET "http://192.168.1.100:32400/library/metadata/12345/thumb?X-Plex-Token=$PLEX_TOKEN"

# Get video thumbnail at specific time (in seconds)
curl -X GET "http://192.168.1.100:32400/photo/:/transcode?url=/library/metadata/12345/thumb/1697123456&width=640&height=360&minSize=1&upscale=1&X-Plex-Token=$PLEX_TOKEN"

# Generate HLS streaming manifest
curl -X GET "http://192.168.1.100:32400/video/:/transcode/universal/start.m3u8?path=/library/metadata/12345&mediaIndex=0&partIndex=0&protocol=hls&fastSeek=1&directPlay=0&directStream=0&subtitleSize=100&audioBoost=100&location=lan&addDebugOverlay=0&autoAdjustQuality=0&directStreamAudio=1&mediaBufferSize=102400&subtitles=burn&Accept-Language=en&X-Plex-Token=$PLEX_TOKEN"
```

--------------------------------

### Create and Manage Playlists (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Demonstrates bash commands for creating, retrieving, adding items to, and deleting playlists via the Plex API. Requires a Plex token and specific format for playlist URIs and item addition. Operations include POST for creation, GET for retrieval, PUT for adding items, and DELETE for removal/deletion.

```bash
# Create a new playlist
curl -X POST "http://192.168.1.100:32400/playlists?X-Plex-Token=$PLEX_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=video" \
  -d "title=Action Movies Marathon" \
  -d "smart=0" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12345,12346,12347"

# Get all playlists
curl -X GET "http://192.168.1.100:32400/playlists?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"

# Add items to playlist
curl -X PUT "http://192.168.1.100:32400/playlists/99999/items?X-Plex-Token=$PLEX_TOKEN" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12348"

# Remove item from playlist
curl -X DELETE "http://192.168.1.100:32400/playlists/99999/items/12345?X-Plex-Token=$PLEX_TOKEN"

# Delete playlist
curl -X DELETE "http://192.168.1.100:32400/playlists/99999?X-Plex-Token=$PLEX_TOKEN"
```

--------------------------------

### Manage Media Collections (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Illustrates bash commands for creating and retrieving media collections in Plex. A collection can be created using a POST request with details like title, type, and associated media URIs. Collections within a specific library section can be fetched using a GET request. Requires a Plex token.

```bash
# Create a collection
curl -X POST "http://192.168.1.100:32400/library/collections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=1" \
  -d "title=The Matrix Collection" \
  -d "sectionId=1" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12345,12346,12347"

# Get all collections in a library
curl -X GET "http://192.168.1.100:32400/library/sections/1/collections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Control Playback with Plex API (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Controls media playback on Plex clients, including starting, pausing, resuming, stopping, and seeking. Requires the target client's identifier and a Plex token. Uses GET requests to specific playback endpoints on the client's IP address.

```bash
# Get available clients
curl -X GET "http://192.168.1.100:32400/clients?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"

# Response
{
  "MediaContainer": {
    "size": 2,
    "Server": [
      {
        "name": "Living Room TV",
        "host": "192.168.1.150",
        "machineIdentifier": "client-123-456",
        "version": "8.30.0",
        "protocol": "plex",
        "product": "Plex for Samsung",
        "deviceClass": "tv",
        "protocolVersion": "1",
        "protocolCapabilities": "timeline,playback,navigation"
      }
    ]
  }
}

# Start playback on client
curl -X GET "http://192.168.1.150:32400/player/playback/playMedia?X-Plex-Token=$PLEX_TOKEN" \
  -H "X-Plex-Target-Client-Identifier: client-123-456" \
  -d "key=/library/metadata/12345" \
  -d "offset=0" \
  -d "machineIdentifier=abc123def456ghi789"

# Pause playback
curl -X GET "http://192.168.1.150:32400/player/playback/pause?X-Plex-Token=$PLEX_TOKEN" \
  -H "X-Plex-Target-Client-Identifier: client-123-456"

# Resume playback
curl -X GET "http://192.168.1.150:32400/player/playback/play?X-Plex-Token=$PLEX_TOKEN" \
  -H "X-Plex-Target-Client-Identifier: client-123-456"

# Stop playback
curl -X GET "http://192.168.1.150:32400/player/playback/stop?X-Plex-Token=$PLEX_TOKEN" \
  -H "X-Plex-Target-Client-Identifier: client-123-456"

# Seek to position (milliseconds)
curl -X GET "http://192.168.1.150:32400/player/playback/seekTo?offset=300000&X-Plex-Token=$PLEX_TOKEN" \
  -H "X-Plex-Target-Client-Identifier: client-123-456"
```

--------------------------------

### Webhook Payload Example for Plex Media Play Event

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Illustrates the JSON payload structure for a 'media.play' event from Plex. This payload contains detailed information about the user, server, player, and the media being played. It's useful for building integrations that react to playback events.

```json
{
  "event": "media.play",
  "user": true,
  "owner": true,
  "Account": {
    "id": 12345678,
    "thumb": "https://plex.tv/users/abc123/avatar",
    "title": "username"
  },
  "Server": {
    "title": "MyPlexServer",
    "uuid": "abc123def456ghi789"
  },
  "Player": {
    "local": true,
    "publicAddress": "203.0.113.42",
    "title": "Living Room TV",
    "uuid": "client-123-456"
  },
  "Metadata": {
    "librarySectionType": "movie",
    "ratingKey": "12345",
    "key": "/library/metadata/12345",
    "parentRatingKey": "12344",
    "grandparentRatingKey": "12343",
    "guid": "plex://movie/5d776b59ad5437001f79c6f8",
    "type": "movie",
    "title": "The Matrix",
    "summary": "A computer hacker learns from mysterious rebels...",
    "year": 1999,
    "thumb": "/library/metadata/12345/thumb/1697123456",
    "art": "/library/metadata/12345/art/1697123456",
    "addedAt": 1697000000,
    "updatedAt": 1697123456
  }
}
```

--------------------------------

### Playback Control API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Control playback on Plex clients, including starting, pausing, resuming, stopping, and seeking.

```APIDOC
## GET /clients

### Description
Retrieves a list of available Plex clients connected to the server.

### Method
GET

### Endpoint
`/clients`

### Request Example
```bash
curl -X GET "http://192.168.1.100:32400/clients?X-Plex-Token=$PLEX_TOKEN"
  -H "Accept: application/json"
```

### Response
#### Success Response (200)
- **MediaContainer** (object) - Contains information about connected clients.
  - **size** (integer) - Number of clients found.
  - **Server** (array) - Array of client objects.
    - **name** (string) - Name of the client device.
    - **host** (string) - Hostname or IP address of the client.
    - **machineIdentifier** (string) - Unique identifier for the client machine.
    - **version** (string) - Version of the Plex client application.
    - **product** (string) - Name of the Plex client product.
    - **deviceClass** (string) - Class of the device (e.g., 'tv', 'mobile').
    - **protocolVersion** (string) - The protocol version supported by the client.
    - **protocolCapabilities** (string) - Capabilities of the client (e.g., 'timeline,playback,navigation').

#### Response Example
```json
{
  "MediaContainer": {
    "size": 2,
    "Server": [
      {
        "name": "Living Room TV",
        "host": "192.168.1.150",
        "machineIdentifier": "client-123-456",
        "version": "8.30.0",
        "product": "Plex for Samsung",
        "deviceClass": "tv",
        "protocolVersion": "1",
        "protocolCapabilities": "timeline,playback,navigation"
      }
    ]
  }
}
```

## GET /player/playback/playMedia

### Description
Starts playback of a media item on a specified Plex client.

### Method
GET

### Endpoint
`/<client_ip_or_hostname>:32400/player/playback/playMedia`

### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **X-Plex-Target-Client-Identifier** (string) - Required - The `machineIdentifier` of the target client.

### Request Body (Form Data)
- **key** (string) - Required - The key of the media to play (e.g., `/library/metadata/12345`).
- **offset** (integer) - Optional - The starting offset in milliseconds. Defaults to 0.
- **machineIdentifier** (string) - Required - The `machineIdentifier` of the server.

### Request Example
```bash
curl -X GET "http://192.168.1.150:32400/player/playback/playMedia?X-Plex-Token=$PLEX_TOKEN"
  -H "X-Plex-Target-Client-Identifier: client-123-456"
  -d "key=/library/metadata/12345"
  -d "offset=0"
  -d "machineIdentifier=abc123def456ghi789"
```

## GET /player/playback/pause

### Description
Pauses playback on a specified Plex client.

### Method
GET

### Endpoint
`/<client_ip_or_hostname>:32400/player/playback/pause`

### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **X-Plex-Target-Client-Identifier** (string) - Required - The `machineIdentifier` of the target client.

### Request Example
```bash
curl -X GET "http://192.168.1.150:32400/player/playback/pause?X-Plex-Token=$PLEX_TOKEN"
  -H "X-Plex-Target-Client-Identifier: client-123-456"
```

## GET /player/playback/play

### Description
Resumes playback on a specified Plex client.

### Method
GET

### Endpoint
`/<client_ip_or_hostname>:32400/player/playback/play`

### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **X-Plex-Target-Client-Identifier** (string) - Required - The `machineIdentifier` of the target client.

### Request Example
```bash
curl -X GET "http://192.168.1.150:32400/player/playback/play?X-Plex-Token=$PLEX_TOKEN"
  -H "X-Plex-Target-Client-Identifier: client-123-456"
```

## GET /player/playback/stop

### Description
Stops playback on a specified Plex client.

### Method
GET

### Endpoint
`/<client_ip_or_hostname>:32400/player/playback/stop`

### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **X-Plex-Target-Client-Identifier** (string) - Required - The `machineIdentifier` of the target client.

### Request Example
```bash
curl -X GET "http://192.168.1.150:32400/player/playback/stop?X-Plex-Token=$PLEX_TOKEN"
  -H "X-Plex-Target-Client-Identifier: client-123-456"
```

## GET /player/playback/seekTo

### Description
Seeks to a specific position in the currently playing media on a Plex client.

### Method
GET

### Endpoint
`/<client_ip_or_hostname>:32400/player/playback/seekTo`

### Query Parameters
- **offset** (integer) - Required - The target position in milliseconds.
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **X-Plex-Target-Client-Identifier** (string) - Required - The `machineIdentifier` of the target client.

### Request Example
```bash
curl -X GET "http://192.168.1.150:32400/player/playback/seekTo?offset=300000&X-Plex-Token=$PLEX_TOKEN"
  -H "X-Plex-Target-Client-Identifier: client-123-456"
```
```

--------------------------------

### Test Plex Media Server Availability and Get Basic Info

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This code snippet uses cURL to test the availability of a Plex Media Server and retrieve basic server information. It requires the server's IP address and port, along with a valid X-Plex-Token for authentication. The response includes details like the server's friendly name, platform, and version.

```bash
# Test server connection
curl -X GET "http://192.168.1.100:32400/?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"

# Response
{
  "MediaContainer": {
    "size": 0,
    "allowCameraUpload": true,
    "allowChannelAccess": true,
    "allowMediaDeletion": true,
    "allowSharing": true,
    "allowSync": true,
    "backgroundProcessing": true,
    "certificate": true,
    "companionProxy": true,
    "friendlyName": "MyPlexServer",
    "machineIdentifier": "abc123def456ghi789",
    "platform": "Linux",
    "platformVersion": "5.15.0",
    "version": "1.40.0.7998"
  }
}
```

--------------------------------

### Manage Metadata with Plex API (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Updates metadata for media items, including titles, summaries, and posters, and manages watched status. Uses PUT and GET requests to specific media endpoints. Requires a Plex token and may require form data for updates.

```bash
# Update movie title and summary
curl -X PUT "http://192.168.1.100:32400/library/metadata/12345?X-Plex-Token=$PLEX_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "title.value=The Matrix (Remastered)" \
  -d "summary.value=Updated summary with additional information" \
  -d "title.locked=1"

# Response: HTTP 200 OK

# Upload custom poster
curl -X POST "http://192.168.1.100:32400/library/metadata/12345/posters?X-Plex-Token=$PLEX_TOKEN" \
  -F "file=@/path/to/poster.jpg"

# Mark item as watched
curl -X GET "http://192.168.1.100:32400/:/scrobble?key=12345&identifier=com.plexapp.plugins.library&X-Plex-Token=$PLEX_TOKEN"

# Mark item as unwatched
curl -X GET "http://192.168.1.100:32400/:/unscrobble?key=12345&identifier=com.plexapp.plugins.library&X-Plex-Token=$PLEX_TOKEN"
```

--------------------------------

### Get all users with Plex server access

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieves a list of all users who have access to the Plex Media Server. This API call requires authentication via X-Plex-Token. The response includes user details such as ID, username, email, and server access information.

```bash
curl -X GET "http://192.168.1.100:32400/accounts?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Get Plex user watch history

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Fetches the watch history for all users on the Plex Media Server. This endpoint requires authentication with a valid PLEX_TOKEN and returns data in JSON format.

```bash
curl -X GET "http://192.168.1.100:32400/status/sessions/history/all?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Get active Plex transcode sessions

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieves a list of all currently active transcoding sessions on the Plex Media Server. Authentication is required using X-Plex-Token. The response provides details about each session, including codecs, progress, and decisions.

```bash
curl -X GET "http://192.168.1.100:32400/transcode/sessions?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Get Active Playback Sessions (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieves information about currently active playback sessions on the Plex Media Server. Requires a Plex token for authentication. The response is in JSON format and includes details about the media being played, the user, and the player device.

```bash
# Get active sessions
curl -X GET "http://192.168.1.100:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Media Retrieval - Get Library Contents

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Fetch all media items (movies, episodes, etc.) within a specific library section. This is useful for listing the content of a particular library, such as all movies or all TV show episodes.

```APIDOC
## Media Retrieval - Get Library Contents

Fetch all media items (movies, episodes, etc.) within a specific library section. This is useful for listing the content of a particular library, such as all movies or all TV show episodes.

### Method

GET

### Endpoint

`http://<SERVER_IP>:<PORT>/library/sections/<SECTION_ID>/all?X-Plex-Token=<YOUR_PLEX_TOKEN>`

*Replace `<SERVER_IP>` with your Plex Media Server's IP address, `<PORT>` with its port (default is 32400), `<SECTION_ID>` with the ID of the library section (obtained from `/library/sections`), and `<YOUR_PLEX_TOKEN>` with your obtained X-Plex-Token.*

### Parameters

#### Path Parameters

- **SECTION_ID** (string) - Required - The ID of the library section to retrieve contents from.

#### Query Parameters

- **X-Plex-Token** (string) - Required - Your authentication token.

### Request Example

```bash
curl -X GET "http://192.168.1.100:32400/library/sections/1/all?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Response

#### Success Response (200)

*The structure of the response will vary depending on the library type (movies, shows, etc.) and will contain a list of media items with their respective metadata (title, year, rating, summary, artwork, etc.).*

#### Response Example

*(Example for a movie library section)*

```json
{
  "MediaContainer": {
    "size": 100,
    "totalSize": 100,
    "offset": 0,
    "Art": "/library/metadata/123/art/1697123456",
    "Metadata": [
      {
        "ratingKey": "123",
        "key": "/library/metadata/123",
        "guid": "plex://movie/607247e2986345001f892581",
        "studio": "Studio Name",
        "type": "movie",
        "title": "Example Movie",
        "originalTitle": "Example Movie",
        "contentRating": "PG-13",
        "rating": 7.5,
        "audienceRating": 7.0,
        "audienceRatingImage": "theaters",
        "summary": "This is a summary of the example movie.",
        "ratingImage": "rottentomatoes",
        "year": 2023,
        "tagline": "An unforgettable journey.",
        "thumb": "/library/metadata/123/thumb/1697123456",
        "art": "/library/metadata/123/art/1697123456",
        "duration": 7200000,
        "originallyAvailableAt": "2023-10-10",
        "addedAt": 1697100000,
        "updatedAt": 1697123456,
        "chapterSource": "agent",
        "primaryEditVersion": 1,
        "hasPremiumVersion": false,
        "Media": [
          {
            "id": 234,
            "duration": 7200000,
            "bitrate": 10000,
            "aspectRatio": 1.78,
            "videoQuality": "1080p",
            "codec": "h264",
            "height": 1080,
            "width": 1920,
            "container": "mp4",
            "audioChannels": 2,
            "audioCodec": "aac",
            "videoFrameRate": "24p",
            "Part": [
              {
                "id": 345,
                "key": "/library/parts/345",
                "duration": 7200000,
                "file": "/media/movies/Example Movie (2023).mp4",
                "size": 7500000000
              }
            ]
          }
        ],
        "Genre": [
          {
            "id": 10,
            "tag": "Action"
          },
          {
            "id": 20,
            "tag": "Adventure"
          }
        ]
      }
      // ... more movie items
    ]
  }
}
```
```

--------------------------------

### List All Libraries on Plex Media Server

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This bash script uses cURL to fetch a list of all configured libraries on a Plex Media Server. It requires the server's address and an X-Plex-Token for authentication. The response is a JSON object containing an array of library sections, each with details like key, type, title, and associated media locations.

```bash
# Get all libraries
curl -X GET "http://192.168.1.100:32400/library/sections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"

# Response
{
  "MediaContainer": {
    "size": 3,
    "Directory": [
      {
        "key": "1",
        "type": "movie",
        "title": "Movies",
        "agent": "tv.plex.agents.movie",
        "scanner": "Plex Movie",
        "language": "en-US",
        "uuid": "abc-123-def-456",
        "updatedAt": 1697123456,
        "createdAt": 1697000000,
        "scannedAt": 1697123456,
        "Location": [
          {
            "id": 1,
            "path": "/media/movies"
          }
        ]
      },
      {
        "key": "2",
        "type": "show",
        "title": "TV Shows",
        "agent": "tv.plex.agents.series",
        "scanner": "Plex TV Series",
        "language": "en-US",
        "uuid": "def-456-ghi-789",
        "updatedAt": 1697123456,
        "createdAt": 1697000000
      }
    ]
  }
}
```

--------------------------------

### Playlists - Creating and Managing Playlists

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Programmatically create, retrieve, update, and delete playlists on your Plex Media Server.

```APIDOC
## Playlists API

### Description
Endpoints for creating, managing, and retrieving playlists.

### Methods and Endpoints

#### Create Playlist
**Method:** POST
**Endpoint:** `/playlists`
**Description:** Creates a new playlist.
**Request Body Parameters (Form URL Encoded):**
- **type** (string) - Required - Type of playlist ('video' or 'audio').
- **title** (string) - Required - The title of the playlist.
- **smart** (integer) - Optional - Set to `1` for a smart playlist, `0` for a regular playlist. Defaults to `0`.
- **uri** (string) - Optional - A comma-separated list of media URIs to add to the playlist upon creation. Format: `server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey1},{ratingKey2},...`
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Get All Playlists
**Method:** GET
**Endpoint:** `/playlists`
**Description:** Retrieves a list of all playlists on the server.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Add Items to Playlist
**Method:** PUT
**Endpoint:** `/playlists/{playlistId}/items`
**Description:** Adds one or more media items to an existing playlist.
**Path Parameters:**
- **playlistId** (string) - Required - The ID of the playlist to modify.
**Request Body Parameters (Form URL Encoded):**
- **uri** (string) - Required - The URI of the media item to add. Format: `server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey}`
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Remove Item from Playlist
**Method:** DELETE
**Endpoint:** `/playlists/{playlistId}/items/{itemId}`
**Description:** Removes a specific media item from a playlist.
**Path Parameters:**
- **playlistId** (string) - Required - The ID of the playlist.
- **itemId** (string) - Required - The ID of the item to remove (usually the ratingKey of the media).
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Delete Playlist
**Method:** DELETE
**Endpoint:** `/playlists/{playlistId}`
**Description:** Deletes an entire playlist.
**Path Parameters:**
- **playlistId** (string) - Required - The ID of the playlist to delete.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Examples

#### Create a New Playlist
```bash
curl -X POST "http://YOUR_PLEX_IP:32400/playlists?X-Plex-Token=$PLEX_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=video" \
  -d "title=Action Movies Marathon" \
  -d "smart=0" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12345,12346,12347"
```

#### Get All Playlists
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/playlists?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

#### Add Items to Playlist
```bash
curl -X PUT "http://YOUR_PLEX_IP:32400/playlists/99999/items?X-Plex-Token=$PLEX_TOKEN" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12348"
```

#### Remove Item from Playlist
```bash
curl -X DELETE "http://YOUR_PLEX_IP:32400/playlists/99999/items/12345?X-Plex-Token=$PLEX_TOKEN"
```

#### Delete Playlist
```bash
curl -X DELETE "http://YOUR_PLEX_IP:32400/playlists/99999?X-Plex-Token=$PLEX_TOKEN"
```

### Responses

#### Create Playlist Response Example (201 Created)
```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {
        "ratingKey": "99999",
        "key": "/playlists/99999/items",
        "guid": "com.plexapp.agents.none://abc-123",
        "type": "playlist",
        "title": "Action Movies Marathon",
        "summary": "",
        "smart": false,
        "playlistType": "video",
        "leafCount": 3,
        "addedAt": 1697123456,
        "updatedAt": 1697123456
      }
    ]
  }
}
```

**Get All Playlists Response:** Returns a `MediaContainer` object similar to the create response, but with an array of all playlists.

**Add/Remove/Delete Responses:** Typically return `200 OK` or `204 No Content` upon success.
```

--------------------------------

### Collections - Managing Media Collections

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Create and manage collections to organize media items within your Plex libraries.

```APIDOC
## Collections API

### Description
Endpoints for creating and managing media collections.

### Methods and Endpoints

#### Create Collection
**Method:** POST
**Endpoint:** `/library/collections`
**Description:** Creates a new collection and adds specified media items to it.
**Request Body Parameters (Form URL Encoded):**
- **type** (integer) - Required - The type of media the collection will contain (e.g., `1` for movies, `2` for shows).
- **title** (string) - Required - The title of the collection.
- **sectionId** (integer) - Required - The ID of the library section where this collection will reside.
- **uri** (string) - Required - A comma-separated list of media URIs to add to the collection. Format: `server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey1},{ratingKey2},...`
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Get Collections in a Library Section
**Method:** GET
**Endpoint:** `/library/sections/{sectionId}/collections`
**Description:** Retrieves a list of all collections within a specific library section.
**Path Parameters:**
- **sectionId** (integer) - Required - The ID of the library section.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Examples

#### Create a Collection
```bash
curl -X POST "http://YOUR_PLEX_IP:32400/library/collections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=1" \
  -d "title=The Matrix Collection" \
  -d "sectionId=1" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12345,12346,12347"
```

#### Get All Collections in a Library Section
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/library/sections/1/collections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Responses

#### Create Collection Response Example (201 Created)
**Response:** Typically returns a `201 Created` status. The body might contain the newly created collection's metadata, similar to the playlist response structure.

#### Get Collections Response Example (200 OK)
```json
{
  "MediaContainer": {
    "size": 2,
    "Metadata": [
      {
        "ratingKey": "10001",
        "key": "/library/collections/10001",
        "type": "collection",
        "title": "The Matrix Collection",
        "summary": "",
        "childCount": 3,
        "leafCount": 3,
        "addedAt": 1697123456,
        "updatedAt": 1697123456
      }
      // ... other collections
    ]
  }
}
```
```

--------------------------------

### Trigger Plex Butler Tasks using Curl

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Shows how to interact with Plex's 'Butler' for server maintenance. Includes commands to check butler status, trigger specific tasks like database backup and optimization, and stop all running tasks via HTTP requests.

```bash
# Get butler status
curl -X GET "http://192.168.1.100:32400/butler?X-Plex-Token=$PLEX_TOKEN"
  -H "Accept: application/json"

# Response
{
  "ButlerTasks": {
    "ButlerTask": [
      {
        "name": "BackupDatabase",
        "interval": 86400,
        "enabled": true,
        "title": "Backup Database",
        "description": "Backup the Plex database"
      },
      {
        "name": "OptimizeDatabase",
        "interval": 86400,
        "enabled": true,
        "title": "Optimize Database",
        "description": "Optimize the Plex database"
      },
      {
        "name": "CleanOldBundles",
        "interval": 604800,
        "enabled": true,
        "title": "Clean Old Bundles",
        "description": "Clean old metadata bundles"
      },
      {
        "name": "CleanOldCacheFiles",
        "interval": 604800,
        "enabled": true,
        "title": "Clean Old Cache Files",
        "description": "Clean old cache files"
      }
    ]
  }
}

# Trigger specific butler task
curl -X POST "http://192.168.1.100:32400/butler/BackupDatabase?X-Plex-Token=$PLEX_TOKEN"

# Response: HTTP 200 OK

# Stop all butler tasks
curl -X POST "http://192.168.1.100:32400/butler/StopAllTasks?X-Plex-Token=$PLEX_TOKEN"

# Common butler tasks:
# - BackupDatabase: Backup Plex database
# - OptimizeDatabase: Vacuum and optimize database
# - CleanOldBundles: Remove old metadata bundles
# - CleanOldCacheFiles: Remove old cache files
# - RefreshLocalMedia: Refresh all local media
# - RefreshLibraries: Refresh all libraries
# - UpgradeMediaAnalysis: Re-analyze media for new features
```

--------------------------------

### Search Media with Plex API (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Searches for media items across all Plex libraries or within specific sections. Requires a Plex token and specifies search query parameters. Returns a JSON object containing matching media metadata.

```bash
# Search for "Matrix" across all libraries
curl -X GET "http://192.168.1.100:32400/search?query=Matrix&X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"

# Response
{
  "MediaContainer": {
    "size": 5,
    "Metadata": [
      {
        "ratingKey": "12345",
        "type": "movie",
        "title": "The Matrix",
        "year": 1999,
        "librarySectionID": 1,
        "librarySectionTitle": "Movies"
      },
      {
        "ratingKey": "12346",
        "type": "movie",
        "title": "The Matrix Reloaded",
        "year": 2003,
        "librarySectionID": 1,
        "librarySectionTitle": "Movies"
      }
    ]
  }
}

# Search within specific library section
curl -X GET "http://192.168.1.100:32400/library/sections/1/search?query=Matrix&X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Download URLs - Generating Direct Media Links

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Endpoints for generating direct download or streaming URLs for media files and thumbnails.

```APIDOC
## Download URLs - Generating Direct Media Links

### Description
Generate direct download or streaming URLs for media files and thumbnails from your Plex Media Server.

### Method
`GET`

### Endpoint
`/library/parts/{part_id}/{file_id}/file.mkv`

### Parameters
#### Query Parameters
- **download** (integer) - Optional - Set to `1` to force a download. Otherwise, it streams the file.
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
# Get media part download URL (force download)
curl -X GET "http://[PLEX_SERVER_IP]:32400/library/parts/[PART_ID]/[FILE_ID]/file.mkv?download=1&X-Plex-Token=$PLEX_TOKEN"

# Get media part streaming URL (no download prompt)
curl -X GET "http://[PLEX_SERVER_IP]:32400/library/parts/[PART_ID]/[FILE_ID]/file.mkv?X-Plex-Token=$PLEX_TOKEN"
```

### Endpoint
`/library/metadata/{metadata_id}/thumb`

### Description
Get the thumbnail or poster image for a metadata item.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/library/metadata/[METADATA_ID]/thumb?X-Plex-Token=$PLEX_TOKEN"
```

### Endpoint
`/photo/:/transcode`

### Description
Get a video thumbnail at a specific time (in seconds).

### Parameters
#### Query Parameters
- **url** (string) - Required - The URL to the thumbnail, typically obtained from `/library/metadata/{metadata_id}/thumb`.
- **width** (integer) - Optional - Desired width of the thumbnail.
- **height** (integer) - Optional - Desired height of the thumbnail.
- **minSize** (integer) - Optional - If set to `1`, ensures minimum dimensions.
- **upscale** (integer) - Optional - If set to `1`, allows upscaling.
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/photo/:/transcode?url=/library/metadata/[METADATA_ID]/thumb/[TIMESTAMP]&width=640&height=360&minSize=1&upscale=1&X-Plex-Token=$PLEX_TOKEN"
```

### Endpoint
`/video/:/transcode/universal/start.m3u8`

### Description
Generate an HLS (HTTP Live Streaming) manifest for the video.

### Parameters
#### Query Parameters
- **path** (string) - Required - The library path to the media item (e.g., `/library/metadata/[METADATA_ID]`).
- **mediaIndex** (integer) - Required - The index of the media part.
- **partIndex** (integer) - Required - The index of the media part.
- **protocol** (string) - Required - Set to `hls` for HLS streaming.
- **fastSeek** (integer) - Optional - If set to `1`, enables fast seeking.
- **directPlay** (integer) - Optional - If set to `1`, attempts direct play.
- **directStream** (integer) - Optional - If set to `1`, attempts direct stream.
- **subtitleSize** (integer) - Optional - The size of subtitles.
- **audioBoost** (integer) - Optional - Audio boost level.
- **location** (string) - Optional - Set to `lan` for local network.
- **addDebugOverlay** (integer) - Optional - If set to `1`, adds a debug overlay.
- **autoAdjustQuality** (integer) - Optional - If set to `1`, automatically adjusts quality.
- **directStreamAudio** (integer) - Optional - If set to `1`, enables direct stream audio.
- **mediaBufferSize** (integer) - Optional - Size of the media buffer.
- **subtitles** (string) - Optional - Subtitle mode (e.g., `burn`).
- **Accept-Language** (string) - Optional - Preferred language for subtitles and audio.
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/video/:/transcode/universal/start.m3u8?path=/library/metadata/[METADATA_ID]&mediaIndex=0&partIndex=0&protocol=hls&fastSeek=1&directPlay=0&directStream=0&subtitleSize=100&audioBoost=100&location=lan&addDebugOverlay=0&autoAdjustQuality=0&directStreamAudio=1&mediaBufferSize=102400&subtitles=burn&Accept-Language=en&X-Plex-Token=$PLEX_TOKEN"
```
```

--------------------------------

### User Management API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Manage users and their access to server resources. Retrieve user information and their associated servers.

```APIDOC
## GET /accounts

### Description
Retrieves a list of all users with access to the Plex Media Server.

### Method
GET

### Endpoint
`/accounts`

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/accounts?X-Plex-Token=$PLEX_TOKEN" -H "Accept: application/json"
```

### Response
#### Success Response (200)
Returns a JSON object containing a list of users and their details.
- **MediaContainer** (object)
  - **size** (integer) - The number of users returned.
  - **User** (array)
    - **id** (integer) - The unique identifier for the user.
    - **title** (string) - The display name of the user.
    - **username** (string) - The username of the user.
    - **email** (string) - The email address of the user.
    - **thumb** (string) - URL to the user's avatar.
    - **home** (boolean) - Indicates if the user is part of the home group.
    - **admin** (boolean) - Indicates if the user is an administrator.
    - **guest** (boolean) - Indicates if the user is a guest.
    - **restricted** (boolean) - Indicates if the user account is restricted.
    - **Server** (array, optional) - List of servers the user has access to.
      - **id** (integer) - Server ID.
      - **serverId** (string) - Server's unique identifier.
      - **machineIdentifier** (string) - Machine identifier of the server.
      - **name** (string) - Name of the server.
      - **lastSeenAt** (integer) - Unix timestamp of the last time the server was seen.
      - **numLibraries** (integer) - Number of libraries on the server.
      - **owned** (boolean) - Indicates if the user owns the server.

#### Response Example
```json
{
  "MediaContainer": {
    "size": 2,
    "User": [
      {
        "id": 12345678,
        "title": "username",
        "username": "username",
        "email": "username@example.com",
        "thumb": "https://plex.tv/users/abc123/avatar",
        "home": false,
        "admin": true,
        "guest": false,
        "restricted": false,
        "Server": [
          {
            "id": 1,
            "serverId": "abc123def456ghi789",
            "machineIdentifier": "abc123def456ghi789",
            "name": "MyPlexServer",
            "lastSeenAt": 1697123456,
            "numLibraries": 3,
            "owned": true
          }
        ]
      },
      {
        "id": 87654321,
        "title": "friend",
        "username": "friend",
        "email": "friend@example.com",
        "thumb": "https://plex.tv/users/def456/avatar",
        "home": false,
        "admin": false,
        "guest": false,
        "restricted": true
      }
    ]
  }
}
```

## GET /status/sessions/history/all

### Description
Retrieves the watch history for all users on the server.

### Method
GET

### Endpoint
`/status/sessions/history/all`

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/status/sessions/history/all?X-Plex-Token=$PLEX_TOKEN" -H "Accept: application/json"
```

### Response
#### Success Response (200)
Returns a JSON object containing the watch history. The structure of this response can be complex and depends on the media played.

#### Response Example
(Response body omitted for brevity, will contain detailed watch history data.)
```

--------------------------------

### Library Management - List All Libraries

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieve a list of all library sections (e.g., Movies, TV Shows, Music) configured on your Plex Media Server. This endpoint is essential for understanding the structure of your media libraries.

```APIDOC
## Library Management - List All Libraries

Retrieve a list of all library sections (e.g., Movies, TV Shows, Music) configured on your Plex Media Server. This endpoint is essential for understanding the structure of your media libraries.

### Method

GET

### Endpoint

`http://<SERVER_IP>:<PORT>/library/sections?X-Plex-Token=<YOUR_PLEX_TOKEN>`

*Replace `<SERVER_IP>` with your Plex Media Server's IP address, `<PORT>` with its port (default is 32400), and `<YOUR_PLEX_TOKEN>` with your obtained X-Plex-Token.*

### Parameters

#### Query Parameters

- **X-Plex-Token** (string) - Required - Your authentication token.

### Request Example

```bash
curl -X GET "http://192.168.1.100:32400/library/sections?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Response

#### Success Response (200)

- **MediaContainer** (object)
  - **size** (integer) - The total number of library sections.
  - **Directory** (array) - An array of library section objects.
    - **key** (string) - The unique identifier for the library section.
    - **type** (string) - The type of media in the library (e.g., "movie", "show", "artist").
    - **title** (string) - The display name of the library section.
    - **agent** (string) - The metadata agent used for this library.
    - **scanner** (string) - The scanner used for this library.
    - **language** (string) - The primary language for metadata.
    - **uuid** (string) - The unique UUID of the library section.
    - **updatedAt** (integer) - Unix timestamp of the last update.
    - **createdAt** (integer) - Unix timestamp of when the library was created.
    - **scannedAt** (integer) - Unix timestamp of when the library was last scanned.
    - **Location** (array, optional) - An array of paths where the media for this library is stored.
      - **id** (integer) - The ID of the location.
      - **path** (string) - The file system path.

#### Response Example

```json
{
  "MediaContainer": {
    "size": 3,
    "Directory": [
      {
        "key": "1",
        "type": "movie",
        "title": "Movies",
        "agent": "tv.plex.agents.movie",
        "scanner": "Plex Movie",
        "language": "en-US",
        "uuid": "abc-123-def-456",
        "updatedAt": 1697123456,
        "createdAt": 1697000000,
        "scannedAt": 1697123456,
        "Location": [
          {
            "id": 1,
            "path": "/media/movies"
          }
        ]
      },
      {
        "key": "2",
        "type": "show",
        "title": "TV Shows",
        "agent": "tv.plex.agents.series",
        "scanner": "Plex TV Series",
        "language": "en-US",
        "uuid": "def-456-ghi-789",
        "updatedAt": 1697123456,
        "createdAt": 1697000000
      }
    ]
  }
}
```
```

--------------------------------

### Trigger Library Scans and Operations (Bash)

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Provides bash commands to refresh and update Plex media libraries. This includes scanning all libraries, specific sections, performing deep scans, analyzing media for features like intro detection, and emptying the trash. Requires a Plex token.

```bash
# Scan all libraries
curl -X GET "http://192.168.1.100:32400/library/sections/all/refresh?X-Plex-Token=$PLEX_TOKEN"

# Scan specific library section
curl -X GET "http://192.168.1.100:32400/library/sections/1/refresh?X-Plex-Token=$PLEX_TOKEN"

# Force deep scan (slower but more thorough)
curl -X GET "http://192.168.1.100:32400/library/sections/1/refresh?force=1&X-Plex-Token=$PLEX_TOKEN"

# Analyze media files (for intro detection, loudness, etc.)
curl -X GET "http://192.168.1.100:32400/library/sections/1/analyze?X-Plex-Token=$PLEX_TOKEN"

# Empty trash for library
curl -X PUT "http://192.168.1.100:32400/library/sections/1/emptyTrash?X-Plex-Token=$PLEX_TOKEN"
```

--------------------------------

### Server Preferences API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieve and update Plex Media Server configuration settings, such as server name and transcoding quality.

```APIDOC
## GET /:/prefs

### Description
Retrieves all server preferences and their current settings.

### Method
GET

### Endpoint
`/:/prefs`

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/:/prefs?X-Plex-Token=$PLEX_TOKEN" -H "Accept: application/json"
```

### Response
#### Success Response (200)
Returns a JSON object containing a list of server settings.
- **MediaContainer** (object)
  - **size** (integer) - The number of settings returned.
  - **Setting** (array)
    - **id** (string) - The unique identifier for the setting.
    - **label** (string) - A human-readable label for the setting.
    - **summary** (string) - A description of the setting.
    - **type** (string) - The data type of the setting (e.g., 'text', 'int', 'boolean').
    - **default** (string) - The default value of the setting.
    - **value** (string) - The current value of the setting.
    - **hidden** (boolean) - Indicates if the setting is hidden from the UI.
    - **advanced** (boolean) - Indicates if the setting is considered advanced.
    - **group** (string) - The group the setting belongs to (e.g., 'general', 'transcoder').
    - **enumValues** (string, optional) - Available enumerated values for the setting, if applicable.

#### Response Example
```json
{
  "MediaContainer": {
    "size": 150,
    "Setting": [
      {
        "id": "FriendlyName",
        "label": "Friendly name",
        "summary": "The name of this server",
        "type": "text",
        "default": "MyPlexServer",
        "value": "MyPlexServer",
        "hidden": false,
        "advanced": false,
        "group": "general"
      },
      {
        "id": "TranscoderQuality",
        "label": "Transcoder quality",
        "summary": "Quality profile for transcoding",
        "type": "int",
        "default": "2",
        "value": "3",
        "hidden": false,
        "advanced": true,
        "group": "transcoder",
        "enumValues": "0:Automatic|1:Prefer high speed encoding|2:Prefer high quality encoding|3:Make my CPU hurt"
      }
    ]
  }
}
```

## PUT /:/prefs

### Description
Updates a specific server preference.

### Method
PUT

### Endpoint
`/:/prefs`

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.
- **[PreferenceID]** (string) - Required - The ID of the preference to update (e.g., `FriendlyName`).
- **[Value]** (string) - Required - The new value for the preference.

### Request Body
This endpoint does not use a request body. Parameters are passed as query parameters.

### Request Example
```bash
curl -X PUT "http://[PLEX_SERVER_IP]:32400/:/prefs?FriendlyName=HomeMediaServer&X-Plex-Token=$PLEX_TOKEN"
```

### Response
#### Success Response (200)
Returns HTTP 200 OK on successful update of the server preference.

#### Response Example
(No response body on success)
```

--------------------------------

### Metadata Management API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Manage media metadata including titles, summaries, posters, and watched status.

```APIDOC
## PUT /library/metadata/{metadataID}

### Description
Updates metadata for a specific media item.

### Method
PUT

### Endpoint
`/library/metadata/<metadataID>`

### Parameters
#### Path Parameters
- **metadataID** (string) - Required - The unique identifier of the metadata to update.

#### Request Body
- **field.value** (string) - Required - The new value for the metadata field (e.g., `title.value`, `summary.value`).
- **field.locked** (integer) - Optional - Set to `1` to lock the metadata field.

### Request Example
```bash
curl -X PUT "http://192.168.1.100:32400/library/metadata/12345?X-Plex-Token=$PLEX_TOKEN"
  -H "Content-Type: application/x-www-form-urlencoded"
  -d "title.value=The Matrix (Remastered)"
  -d "summary.value=Updated summary with additional information"
  -d "title.locked=1"
```

### Response
#### Success Response (200)
HTTP 200 OK

## POST /library/metadata/{metadataID}/posters

### Description
Uploads a custom poster for a media item.

### Method
POST

### Endpoint
`/library/metadata/<metadataID>/posters`

### Parameters
#### Path Parameters
- **metadataID** (string) - Required - The unique identifier of the metadata to update.

#### Request Body
- **file** (file) - Required - The image file for the poster.

### Request Example
```bash
curl -X POST "http://192.168.1.100:32400/library/metadata/12345/posters?X-Plex-Token=$PLEX_TOKEN"
  -F "file=@/path/to/poster.jpg"
```

## GET /:/:scrobble

### Description
Marks a media item as watched.

### Method
GET

### Endpoint
`/:/scrobble?key=<media_key>&identifier=<media_identifier>`

### Query Parameters
- **key** (string) - Required - The key of the media item.
- **identifier** (string) - Required - The identifier of the media item (e.g., `com.plexapp.plugins.library`).

### Request Example
```bash
curl -X GET "http://192.168.1.100:32400/:/scrobble?key=12345&identifier=com.plexapp.plugins.library&X-Plex-Token=$PLEX_TOKEN"
```

## GET /:/:unscrobble

### Description
Marks a media item as unwatched.

### Method
GET

### Endpoint
`/:/unscrobble?key=<media_key>&identifier=<media_identifier>`

### Query Parameters
- **key** (string) - Required - The key of the media item.
- **identifier** (string) - Required - The identifier of the media item (e.g., `com.plexapp.plugins.library`).

### Request Example
```bash
curl -X GET "http://192.168.1.100:32400/:/unscrobble?key=12345&identifier=com.plexapp.plugins.library&X-Plex-Token=$PLEX_TOKEN"
```
```

--------------------------------

### Add items to a Plex collection using API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Adds specified media items to a Plex collection using the PUT method. Requires the collection's ID and the URI of the media to add. The PLEX_TOKEN must be set in your environment.

```bash
curl -X PUT "http://192.168.1.100:32400/library/collections/88888/items?X-Plex-Token=$PLEX_TOKEN" \
  -d "uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12348"
```

--------------------------------

### Authentication - Obtaining X-Plex-Token

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This section details how to obtain an X-Plex-Token for authenticating with the Plex Media Server API. It shows the curl command for signing in via Plex.tv and extracting the authentication token from the response.

```APIDOC
## Authentication - Obtaining X-Plex-Token

This section details how to obtain an X-Plex-Token for authenticating with the Plex Media Server API. It shows the curl command for signing in via Plex.tv and extracting the authentication token from the response.

### Method

POST

### Endpoint

https://plex.tv/users/sign_in.json

### Parameters

#### Request Body

- **user[login]** (string) - Required - The username or email for Plex account login.
- **user[password]** (string) - Required - The password for Plex account login.

#### Headers

- **Content-Type**: application/x-www-form-urlencoded
- **X-Plex-Product**: "MyApp" (Your application name)
- **X-Plex-Version**: "1.0" (Your application version)
- **X-Plex-Client-Identifier**: "unique-client-id-12345" (A unique identifier for your client application)

### Request Example

```bash
curl -X POST "https://plex.tv/users/sign_in.json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Plex-Product: MyApp" \
  -H "X-Plex-Version: 1.0" \
  -H "X-Plex-Client-Identifier: unique-client-id-12345" \
  -d "user[login]=username@example.com" \
  -d "user[password]=password123"
```

### Response

#### Success Response (200)

- **user** (object)
  - **id** (integer) - The user's unique Plex ID.
  - **uuid** (string) - The user's UUID.
  - **username** (string) - The username.
  - **email** (string) - The user's email address.
  - **authToken** (string) - The authentication token (X-Plex-Token) to be used in subsequent requests.

#### Response Example

```json
{
  "user": {
    "id": 12345678,
    "uuid": "abc123def456",
    "username": "username",
    "email": "username@example.com",
    "authToken": "xxxxxxxxxxxxxxxxxxxx"
  }
}
```
```

--------------------------------

### Search API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Search for media items across all libraries or within specific sections using the search endpoint.

```APIDOC
## GET /search

### Description
Searches for media items across all libraries.

### Method
GET

### Endpoint
`/search?query=<search_term>`

### Query Parameters
- **query** (string) - Required - The search term for the media.

### Request Example
```bash
curl -X GET "http://192.168.1.100:32400/search?query=Matrix&X-Plex-Token=$PLEX_TOKEN"
  -H "Accept: application/json"
```

### Response
#### Success Response (200)
- **MediaContainer** (object) - Contains search results.
  - **size** (integer) - Number of results.
  - **Metadata** (array) - Array of media items matching the search.
    - **ratingKey** (string) - Unique identifier for the media item.
    - **type** (string) - Type of media (e.g., 'movie', 'show').
    - **title** (string) - Title of the media item.
    - **year** (integer) - Year of release.
    - **librarySectionID** (integer) - ID of the library section.
    - **librarySectionTitle** (string) - Title of the library section.

#### Response Example
```json
{
  "MediaContainer": {
    "size": 5,
    "Metadata": [
      {
        "ratingKey": "12345",
        "type": "movie",
        "title": "The Matrix",
        "year": 1999,
        "librarySectionID": 1,
        "librarySectionTitle": "Movies"
      }
    ]
  }
}
```

## GET /library/sections/{sectionID}/search

### Description
Searches for media items within a specific library section.

### Method
GET

### Endpoint
`/library/sections/<sectionID>/search?query=<search_term>`

### Query Parameters
- **query** (string) - Required - The search term for the media.

### Request Example
```bash
curl -X GET "http://192.168.1.100:32400/library/sections/1/search?query=Matrix&X-Plex-Token=$PLEX_TOKEN"
```
```

--------------------------------

### Server Connection - Testing Server Availability

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This endpoint allows you to test the connection to your Plex Media Server and retrieve basic information about it. This is useful for verifying server status before making other API calls.

```APIDOC
## Server Connection - Testing Server Availability

This endpoint allows you to test the connection to your Plex Media Server and retrieve basic information about it. This is useful for verifying server status before making other API calls.

### Method

GET

### Endpoint

`http://<SERVER_IP>:<PORT>/?X-Plex-Token=<YOUR_PLEX_TOKEN>`

*Replace `<SERVER_IP>` with your Plex Media Server's IP address, `<PORT>` with its port (default is 32400), and `<YOUR_PLEX_TOKEN>` with your obtained X-Plex-Token.*

### Parameters

#### Query Parameters

- **X-Plex-Token** (string) - Required - Your authentication token.

### Request Example

```bash
curl -X GET "http://192.168.1.100:32400/?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Response

#### Success Response (200)

- **MediaContainer** (object)
  - **size** (integer) - The number of items in the container (usually 0 for this endpoint).
  - **allowCameraUpload** (boolean) - Indicates if camera upload is allowed.
  - **allowChannelAccess** (boolean) - Indicates if channel access is allowed.
  - **allowMediaDeletion** (boolean) - Indicates if media deletion is allowed.
  - **allowSharing** (boolean) - Indicates if sharing is allowed.
  - **allowSync** (boolean) - Indicates if sync is allowed.
  - **backgroundProcessing** (boolean) - Indicates if background processing is enabled.
  - **certificate** (boolean) - Indicates if a certificate is present.
  - **companionProxy** (boolean) - Indicates if the companion proxy is enabled.
  - **friendlyName** (string) - The friendly name of the Plex Media Server.
  - **machineIdentifier** (string) - The unique identifier for the Plex Media Server machine.
  - **platform** (string) - The operating system platform of the server.
  - **platformVersion** (string) - The version of the operating system platform.
  - **version** (string) - The version of Plex Media Server.

#### Response Example

```json
{
  "MediaContainer": {
    "size": 0,
    "allowCameraUpload": true,
    "allowChannelAccess": true,
    "allowMediaDeletion": true,
    "allowSharing": true,
    "allowSync": true,
    "backgroundProcessing": true,
    "certificate": true,
    "companionProxy": true,
    "friendlyName": "MyPlexServer",
    "machineIdentifier": "abc123def456ghi789",
    "platform": "Linux",
    "platformVersion": "5.15.0",
    "version": "1.40.0.7998"
  }
}
```
```

--------------------------------

### Webhooks API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Configure webhooks to receive real-time notifications about events occurring on your Plex Media Server.

```APIDOC
## Webhooks Configuration

### Description
Webhooks allow your Plex Media Server to send real-time notifications to a specified URL when certain events occur (e.g., media playback start/stop, library changes). Configuration is typically done through the Plex Web UI or specific settings endpoints not detailed here.

### Method
(Configuration method varies, often involves POST requests to a settings endpoint or UI interaction)

### Endpoint
(Specific endpoint for webhook configuration depends on Plex version and implementation)

### Parameters
(Parameters for configuration depend on the method used, but typically include):
- **Webhook URL** (string) - The URL to send webhook notifications to.
- **Event Types** (array of strings) - The types of events to receive notifications for.
- **X-Plex-Token** (string) - Your Plex authentication token (if using API for configuration).

### Request Body
(Varies based on configuration method. May include URL and event subscriptions.)

### Request Example
(Example using `curl` to configure a webhook is complex and highly dependent on the specific API version and available endpoints. Refer to Plex documentation for detailed API-based configuration.)

### Response
#### Success Response
(Typically a 200 OK or similar indication of successful configuration.)

#### Response Example
(Response varies based on configuration method.)
```

--------------------------------

### Authenticate with Plex.tv and Obtain X-Plex-Token

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This snippet demonstrates how to authenticate with Plex.tv using cURL to obtain an X-Plex-Token. This token is crucial for authorizing subsequent API requests to the Plex Media Server. It requires providing user credentials and client identifiers.

```bash
# Authenticate via Plex.tv to get token
curl -X POST "https://plex.tv/users/sign_in.json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Plex-Product: MyApp" \
  -H "X-Plex-Version: 1.0" \
  -H "X-Plex-Client-Identifier: unique-client-id-12345" \
  -d "user[login]=username@example.com" \
  -d "user[password]=password123"

# Response
{
  "user": {
    "id": 12345678,
    "uuid": "abc123def456",
    "username": "username",
    "email": "username@example.com",
    "authToken": "xxxxxxxxxxxxxxxxxxxx"
  }
}

# Use token in subsequent requests
export PLEX_TOKEN="xxxxxxxxxxxxxxxxxxxx"
```

--------------------------------

### Retrieve Contents of a Specific Plex Library Section

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

This bash snippet demonstrates how to fetch all media items from a specific library section on a Plex Media Server. It uses cURL with the library section's key and an X-Plex-Token for authentication. The output is a JSON object containing the media items within that section.

```bash
# Get all movies from library section 1
curl -X GET "http://192.168.1.100:32400/library/sections/1/all?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

--------------------------------

### Library Scanning - Refresh and Update Libraries

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Trigger library scans to detect new media or refresh metadata, and perform other library maintenance tasks.

```APIDOC
## Library Scanning Endpoints

### Description
These endpoints allow you to trigger library scans, analyze media, and manage library trash.

### Methods and Endpoints

#### Scan All Libraries
**Method:** GET
**Endpoint:** `/library/sections/all/refresh`
**Description:** Initiates a scan for all libraries on the server.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Scan Specific Library Section
**Method:** GET
**Endpoint:** `/library/sections/{sectionId}/refresh`
**Description:** Initiates a scan for a specific library section.
**Path Parameters:**
- **sectionId** (integer) - Required - The ID of the library section to scan.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Force Deep Scan
**Method:** GET
**Endpoint:** `/library/sections/{sectionId}/refresh`
**Description:** Performs a more thorough (and potentially slower) scan of a specific library section.
**Path Parameters:**
- **sectionId** (integer) - Required - The ID of the library section to scan.
**Query Parameters:**
- **force** (integer) - Required - Set to `1` to enable deep scan.
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Analyze Media
**Method:** GET
**Endpoint:** `/library/sections/{sectionId}/analyze`
**Description:** Analyzes media files within a specific library section for features like intro detection and loudness analysis.
**Path Parameters:**
- **sectionId** (integer) - Required - The ID of the library section to analyze.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

#### Empty Trash
**Method:** PUT
**Endpoint:** `/library/sections/{sectionId}/emptyTrash`
**Description:** Empties the trash for a specific library section, removing deleted media that is no longer referenced.
**Path Parameters:**
- **sectionId** (integer) - Required - The ID of the library section.
**Query Parameters:**
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Examples

#### Scan All Libraries
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/library/sections/all/refresh?X-Plex-Token=$PLEX_TOKEN"
```

#### Scan Specific Library Section
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/library/sections/1/refresh?X-Plex-Token=$PLEX_TOKEN"
```

#### Force Deep Scan
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/library/sections/1/refresh?force=1&X-Plex-Token=$PLEX_TOKEN"
```

#### Analyze Media
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/library/sections/1/analyze?X-Plex-Token=$PLEX_TOKEN"
```

#### Empty Trash
```bash
curl -X PUT "http://YOUR_PLEX_IP:32400/library/sections/1/emptyTrash?X-Plex-Token=$PLEX_TOKEN"
```

### Responses
**Success Response (200 OK)** is generally returned for these operations, often with no specific JSON payload indicating completion unless an error occurs.
```

--------------------------------

### Collections API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Manage collections within your Plex Media Server library. This includes adding items to existing collections.

```APIDOC
## PUT /library/collections/{collectionID}/items

### Description
Adds one or more items to a specified collection.

### Method
PUT

### Endpoint
`/library/collections/{collectionID}/items`

### Parameters
#### Path Parameters
- **collectionID** (string) - Required - The ID of the collection to which items will be added.

#### Query Parameters
- **uri** (string) - Required - The URI of the item to add. Format: `server://<server_id>/com.plexapp.plugins.library/library/metadata/<metadata_id>`
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body. Parameters are passed as query parameters or form data.

### Request Example
```bash
curl -X PUT "http://[PLEX_SERVER_IP]:32400/library/collections/88888/items?uri=server://abc123def456ghi789/com.plexapp.plugins.library/library/metadata/12348&X-Plex-Token=$PLEX_TOKEN"
```

### Response
#### Success Response (200)
Returns an empty response with HTTP 200 OK on success.

#### Response Example
(No response body on success)
```

--------------------------------

### Butler Tasks - Triggering Maintenance Operations

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

API endpoints for retrieving the status of and triggering Plex Media Server maintenance tasks.

```APIDOC
## Butler Tasks - Triggering Maintenance Operations

### Description
Execute server maintenance and optimization tasks programmatically using the Butler API.

### Method
`GET`

### Endpoint
`/butler`

### Description
Get the current status and configuration of all butler tasks.

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/butler?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Response
#### Success Response (200)
```json
{
  "ButlerTasks": {
    "ButlerTask": [
      {
        "name": "BackupDatabase",
        "interval": 86400,
        "enabled": true,
        "title": "Backup Database",
        "description": "Backup the Plex database"
      },
      {
        "name": "OptimizeDatabase",
        "interval": 86400,
        "enabled": true,
        "title": "Optimize Database",
        "description": "Optimize the Plex database"
      },
      {
        "name": "CleanOldBundles",
        "interval": 604800,
        "enabled": true,
        "title": "Clean Old Bundles",
        "description": "Clean old metadata bundles"
      },
      {
        "name": "CleanOldCacheFiles",
        "interval": 604800,
        "enabled": true,
        "title": "Clean Old Cache Files",
        "description": "Clean old cache files"
      }
    ]
  }
}
```

### Method
`POST`

### Endpoint
`/butler/{task_name}`

### Description
Trigger a specific butler task to run immediately.

### Parameters
#### Path Parameters
- **task_name** (string) - Required - The name of the butler task to trigger (e.g., `BackupDatabase`, `OptimizeDatabase`).

#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X POST "http://[PLEX_SERVER_IP]:32400/butler/BackupDatabase?X-Plex-Token=$PLEX_TOKEN"
```

### Response
#### Success Response (200)
HTTP 200 OK

### Method
`POST`

### Endpoint
`/butler/StopAllTasks`

### Description
Stops all currently running butler tasks.

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X POST "http://[PLEX_SERVER_IP]:32400/butler/StopAllTasks?X-Plex-Token=$PLEX_TOKEN"
```

### Response
#### Success Response (200)
HTTP 200 OK

### Common Butler Tasks
- **BackupDatabase**: Backup Plex database.
- **OptimizeDatabase**: Vacuum and optimize database.
- **CleanOldBundles**: Remove old metadata bundles.
- **CleanOldCacheFiles**: Remove old cache files.
- **RefreshLocalMedia**: Refresh all local media.
- **RefreshLibraries**: Refresh all libraries.
- **UpgradeMediaAnalysis**: Re-analyze media for new features.
```

--------------------------------

### Transcoding Sessions API

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Monitor and control active transcoding sessions on your Plex Media Server. View session details and terminate sessions.

```APIDOC
## GET /transcode/sessions

### Description
Retrieves a list of all currently active transcode sessions.

### Method
GET

### Endpoint
`/transcode/sessions`

### Parameters
#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body.

### Request Example
```bash
curl -X GET "http://[PLEX_SERVER_IP]:32400/transcode/sessions?X-Plex-Token=$PLEX_TOKEN" -H "Accept: application/json"
```

### Response
#### Success Response (200)
Returns a JSON object containing details of active transcode sessions.
- **MediaContainer** (object)
  - **size** (integer) - The number of active transcode sessions.
  - **TranscodeSession** (array)
    - **key** (string) - Unique identifier for the transcode session.
    - **throttled** (boolean) - Indicates if the session is being throttled.
    - **complete** (boolean) - Indicates if the transcode is complete.
    - **progress** (number) - Progress of the transcode in percentage.
    - **size** (integer) - Total size of the transcoded media in bytes.
    - **speed** (number) - Current transcoding speed.
    - **remaining** (integer) - Estimated time remaining in seconds.
    - **context** (string) - The context of the transcode (e.g., 'streaming').
    - **sourceVideoCodec** (string) - The video codec of the source media.
    - **sourceAudioCodec** (string) - The audio codec of the source media.
    - **videoDecision** (string) - Decision made for video stream (e.g., 'transcode', 'directplay').
    - **audioDecision** (string) - Decision made for audio stream (e.g., 'transcode', 'directstream').
    - **subtitleDecision** (string) - Decision made for subtitles (e.g., 'burn', 'copy', 'none').
    - **protocol** (string) - The protocol used for streaming.
    - **container** (string) - The container format of the transcoded media.
    - **videoCodec** (string) - The video codec of the transcoded media.
    - **audioCodec** (string) - The audio codec of the transcoded media.
    - **audioChannels** (integer) - Number of audio channels.
    - **width** (integer) - Width of the video.
    - **height** (integer) - Height of the video.
    - **transcodeHwRequested** (boolean) - Indicates if hardware transcoding was requested.
    - **transcodeHwDecoding** (string) - Hardware decoding used (e.g., 'linux').
    - **transcodeHwEncoding** (string) - Hardware encoding used (e.g., 'linux').

#### Response Example
```json
{
  "MediaContainer": {
    "size": 1,
    "TranscodeSession": [
      {
        "key": "transcode-key-123",
        "throttled": false,
        "complete": false,
        "progress": 15.5,
        "size": 500000000,
        "speed": 2.5,
        "remaining": 280,
        "context": "streaming",
        "sourceVideoCodec": "hevc",
        "sourceAudioCodec": "eac3",
        "videoDecision": "transcode",
        "audioDecision": "directstream",
        "subtitleDecision": "burn",
        "protocol": "http",
        "container": "mkv",
        "videoCodec": "h264",
        "audioCodec": "aac",
        "audioChannels": 2,
        "width": 1920,
        "height": 1080,
        "transcodeHwRequested": true,
        "transcodeHwDecoding": "linux",
        "transcodeHwEncoding": "linux"
      }
    ]
  }
}
```

## DELETE /transcode/sessions/{sessionKey}

### Description
Terminates a specific active transcode session.

### Method
DELETE

### Endpoint
`/transcode/sessions/{sessionKey}`

### Parameters
#### Path Parameters
- **sessionKey** (string) - Required - The unique key of the transcode session to terminate.

#### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Body
This endpoint does not use a request body.

### Request Example
```bash
curl -X DELETE "http://[PLEX_SERVER_IP]:32400/transcode/sessions/transcode-key-123?X-Plex-Token=$PLEX_TOKEN"
```

### Response
#### Success Response (200)
Returns HTTP 200 OK on successful termination of the transcode session.

#### Response Example
(No response body on success)
```

--------------------------------

### Playback Sessions - Monitoring Active Playback

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Retrieve information about currently active playback sessions on the Plex Media Server.

```APIDOC
## GET /status/sessions

### Description
Retrieves information about currently active playback sessions on the server.

### Method
GET

### Endpoint
/status/sessions

### Query Parameters
- **X-Plex-Token** (string) - Required - Your Plex authentication token.

### Request Example
```bash
curl -X GET "http://YOUR_PLEX_IP:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN" \
  -H "Accept: application/json"
```

### Response
#### Success Response (200)
- **MediaContainer** (object) - Contains information about playback sessions.
  - **size** (integer) - The number of active sessions.
  - **Metadata** (array) - An array of objects, each representing an active session.
    - **sessionKey** (string) - Unique identifier for the session.
    - **ratingKey** (string) - The rating key of the media being played.
    - **key** (string) - The API path to the media item.
    - **type** (string) - The type of media (e.g., 'movie', 'episode').
    - **title** (string) - The title of the media.
    - **duration** (integer) - The total duration of the media in milliseconds.
    - **viewOffset** (integer) - The current playback position in milliseconds.
    - **User** (object) - Information about the user.
      - **id** (integer) - The user's ID.
      - **title** (string) - The username.
    - **Player** (object) - Information about the player client.
      - **address** (string) - The IP address of the player.
      - **device** (string) - The device name of the player.
      - **machineIdentifier** (string) - The unique machine identifier of the client.
      - **model** (string) - The model of the player device.
      - **platform** (string) - The platform of the player (e.g., 'Samsung').
      - **platformVersion** (string) - The version of the player platform.
      - **product** (string) - The product name of the player (e.g., 'Plex for Samsung').
      - **state** (string) - The current playback state (e.g., 'playing', 'paused').
      - **title** (string) - The title of the player (e.g., 'Living Room TV').
    - **Session** (object) - Session-specific details.
      - **id** (string) - The session ID.
      - **bandwidth** (integer) - The current bandwidth usage in kbps.
      - **location** (string) - The network location ('lan' or 'wan').
    - **TranscodeSession** (object, optional) - Details if transcoding is occurring.
      - **key** (string) - The key for the transcode session.
      - **throttled** (boolean) - Whether the session is being throttled.
      - **complete** (boolean) - Whether transcoding is complete.
      - **progress** (number) - The progress of the transcode in percentage.
      - **size** (integer) - The total size of the transcoded file in bytes.
      - **speed** (number) - The speed of the transcode.
      - **videoDecision** (string) - The decision for video transcoding.
      - **audioDecision** (string) - The decision for audio transcoding.
      - **protocol** (string) - The streaming protocol used.
      - **container** (string) - The container format.
      - **videoCodec** (string) - The video codec.
      - **audioCodec** (string) - The audio codec.
      - **width** (integer) - The video width.
      - **height** (integer) - The video height.

#### Response Example
```json
{
  "MediaContainer": {
    "size": 1,
    "Metadata": [
      {
        "sessionKey": "1",
        "ratingKey": "12345",
        "key": "/library/metadata/12345",
        "type": "movie",
        "title": "The Matrix",
        "duration": 8160000,
        "viewOffset": 1500000,
        "User": {
          "id": 12345678,
          "title": "username"
        },
        "Player": {
          "address": "192.168.1.150",
          "device": "Samsung TV",
          "machineIdentifier": "client-123-456",
          "model": "QN90A",
          "platform": "Samsung",
          "platformVersion": "6.0",
          "product": "Plex for Samsung",
          "state": "playing",
          "title": "Living Room TV"
        },
        "Session": {
          "id": "session-abc-123",
          "bandwidth": 5000,
          "location": "lan"
        },
        "TranscodeSession": {
          "key": "transcode-key-123",
          "throttled": false,
          "complete": false,
          "progress": 15.5,
          "size": 500000000,
          "speed": 2.5,
          "videoDecision": "transcode",
          "audioDecision": "directstream",
          "protocol": "http",
          "container": "mkv",
          "videoCodec": "h264",
          "audioCodec": "aac",
          "width": 1920,
          "height": 1080
        }
      }
    ]
  }
}
```
```

--------------------------------

### Update a Plex server preference

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Modifies a specific server preference setting on the Plex Media Server. This uses an HTTP PUT request and requires the PLEX_TOKEN for authentication. The preference ID and new value are provided as data.

```bash
curl -X PUT "http://192.168.1.100:32400/:/prefs?X-Plex-Token=$PLEX_TOKEN" \
  -d "FriendlyName=HomeMediaServer"
```

--------------------------------

### Kill a Plex transcode session

Source: https://context7.com/context7/developer_plex_tv_pms/llms.txt

Terminates a specific active transcoding session on the Plex Media Server. This is achieved using an HTTP DELETE request with the session's key. Authentication with X-Plex-Token is mandatory.

```bash
curl -X DELETE "http://192.168.1.100:32400/transcode/sessions/transcode-key-123?X-Plex-Token=$PLEX_TOKEN"
```

=== COMPLETE CONTENT === This response contains all available snippets from this library. No additional content exists. Do not make further requests.
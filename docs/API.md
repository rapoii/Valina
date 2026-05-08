# API Documentation

## Firebase Firestore Structure

### Collections

#### `users/{uid}`
Dokumen profil user.

```typescript
{
  displayName: string,
  email: string,
  photoURL?: string,
  createdAt: Timestamp,
  lastLoginAt: Timestamp,
  // Cycle settings
  cycleLength: number,      // default: 28
  periodLength: number,     // default: 5
  gender: 'female' | 'male',
  goal: 'track' | 'pregnancy' | 'contraception',
  // Partner
  partnerCode?: string,
  linkedPartnerUid?: string
}
```

#### `users/{uid}/cycles/{cycleId}`
Data satu siklus menstruasi.

```typescript
{
  startDate: Timestamp,
  endDate?: Timestamp,
  createdAt: Timestamp,
  // Computed
  periodLength: number,
  cycleLength: number
}
```

#### `users/{uid}/logs/{date}`
Log harian untuk tracking.

```typescript
{
  date: string,              // YYYY-MM-DD
  hasFlow: boolean,
  flowIntensity?: 'light' | 'medium' | 'heavy',
  mood?: string[],
  symptoms?: string[],
  notes?: string
}
```

#### `users/{uid}/notifications`
Pengaturan notifikasi.

```typescript
{
  periodReminder: boolean,
  ovulationReminder: boolean,
  reminderDaysBefore: number
}
```

#### `partnerCodes/{code}`
Data kode partner untuk linking.

```typescript
{
  ownerUid: string,
  ownerName: string,
  createdAt: Timestamp,
  linkedUid?: string,
  linkedAt?: Timestamp
}
```

## OpenRouter API

### Endpoint

```
POST https://openrouter.ai/api/v1/chat/completions
```

### Headers

```http
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

### Request Body

```json
{
  "model": "meta-llama/llama-3-8b-instruct:free",
  "messages": [
    {
      "role": "system",
      "content": "Kamu adalah AI assistant untuk aplikasi pelacak menstruasi..."
    },
    {
      "role": "user",
      "content": "Pertanyaan user..."
    }
  ]
}
```

### Response

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Jawaban AI..."
      }
    }
  ]
}
```

## Firebase Rules

### Basic Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Partner codes are readable by anyone
    match /partnerCodes/{code} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `auth/user-not-found` | User tidak ditemukan |
| `auth/wrong-password` | Password salah |
| `auth/email-already-in-use` | Email sudah terdaftar |
| `firestore/permission-denied` | Tidak ada akses ke data |
| `openrouter/api-error` | OpenRouter API error |

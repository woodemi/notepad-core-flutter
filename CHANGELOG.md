## 0.4.0

### NotepadClient

- Authorization: Add `claimAuth` & `disclaimAuth`
- Device info: Add `getDeviceName`, `setDeviceName`, `getBatteryInfo`, `getDeviceDate`, `setDeviceDate`, `getAutoLockTime`, `setAutoLockTime`, `getVersionInfo`
- Offline memo: Add `getMemoSummary`, `getMemoInfo`, `importMemo`, `deleteMemo`

## 0.3.0

- Add `setMode` to `NotepadClient`, with `NotepadMode.Sync`
- Add `NotepadClientCallback` with `handlePointer`

## 0.2.0

### Extract `NotepadConnector`
- Add `connect` & `disconnect`
- Add `ConnectionChangeHandler`

### Add `NotepadClient`
- Add `completeConnection`

## 0.1.0

- Support Woodemi notepad
- Add `startScan` & `stopScan`
- Add `scanResultStream`

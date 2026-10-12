# Garmin companion

This Connect IQ watch app provides manual SOS, SOS cancellation, Heads Up,
check-in, current safety state, haptics, battery heartbeat, and a ten-second
false-alarm window. It does not perform automatic seizure detection.

## Pairing

1. In the Flutter app, open Profile > Safety readiness > Pair a Garmin watch.
2. Open Seizure Alert on the watch.
3. Enter the six-digit code with Up/Down and Select.
4. The watch exchanges the short-lived code for a revocable 256-bit token over
   HTTPS. The long token remains in Connect IQ secure application storage.

## Build

Install the Garmin Connect IQ SDK and configure a developer key, then run:

```powershell
monkeyc -f monkey.jungle -d fenix7 -o bin/SeizureAlert.prg -y <developer-key>
```

The target list in `manifest.xml` is intentionally small for the first device
validation pass. Add devices only after checking screen layout, input controls,
communications, and battery behaviour on that family.

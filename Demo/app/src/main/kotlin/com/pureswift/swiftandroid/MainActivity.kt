package com.pureswift.swiftandroid

import android.Manifest
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import com.pureswift.swiftandroid.bridge.BluetoothDemoBridge
import com.pureswift.swiftandroid.ui.theme.SwiftAndroidTheme

class MainActivity : ComponentActivity() {

    init {
        NativeLibrary.shared()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Request permissions on startup.
        val permissions = arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT
        )
        ActivityCompat.requestPermissions(this, permissions, 1)

        setContent {
            SwiftAndroidTheme {
                ScannerScreen()
            }
        }
    }
}

data class Device(
    val address: String,
    val name: String,
    val rssi: Long
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScannerScreen() {
    // Bridge callbacks arrive on Swift background threads; hop to main before touching state.
    val mainHandler = remember { Handler(Looper.getMainLooper()) }

    var scanning by remember { mutableStateOf(false) }
    val devices = remember { mutableStateMapOf<String, Device>() }
    var selected by remember { mutableStateOf<Device?>(null) }
    var status by remember { mutableStateOf("") }
    val services = remember { mutableStateListOf<String>() }

    fun startScan() {
        devices.clear()
        scanning = true
        BluetoothDemoBridge.startScan { address, name, rssi ->
            mainHandler.post { devices[address] = Device(address, name, rssi) }
        }
    }

    fun stopScan() {
        BluetoothDemoBridge.stopScan()
        scanning = false
    }

    fun connect(device: Device) {
        stopScan()
        selected = device
        status = "Connecting…"
        services.clear()
        BluetoothDemoBridge.connect(
            device.address,
            { mainHandler.post { status = "Connected" } },
            { uuid -> mainHandler.post { services.add(uuid) } },
            { message -> mainHandler.post { status = "Error: $message" } }
        )
    }

    fun disconnect() {
        selected?.let { BluetoothDemoBridge.disconnect(it.address) }
        selected = null
        services.clear()
        status = ""
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Bluetooth LE") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            val device = selected
            if (device == null) {
                Button(onClick = { if (scanning) stopScan() else startScan() }) {
                    Text(if (scanning) "Stop Scan" else "Start Scan")
                }
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(devices.values.sortedByDescending { it.rssi }) { item ->
                        DeviceRow(item) { connect(item) }
                    }
                }
            } else {
                Text(
                    text = device.name.ifEmpty { device.address },
                    style = MaterialTheme.typography.titleLarge
                )
                Text(status, style = MaterialTheme.typography.bodyMedium)
                HorizontalDivider()
                Text("Services", style = MaterialTheme.typography.titleMedium)
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(services) { uuid ->
                        Text(uuid, style = MaterialTheme.typography.bodySmall)
                    }
                }
                Button(onClick = { disconnect() }) {
                    Text("Disconnect")
                }
            }
        }
    }
}

@Composable
fun DeviceRow(device: Device, onClick: () -> Unit) {
    Card(modifier = Modifier
        .fillMaxWidth()
        .clickable { onClick() }
    ) {
        Row(modifier = Modifier.padding(12.dp)) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = device.name.ifEmpty { "(unknown)" },
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = device.address,
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Spacer(modifier = Modifier.weight(0.1f))
            Text(
                text = "${device.rssi} dBm",
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

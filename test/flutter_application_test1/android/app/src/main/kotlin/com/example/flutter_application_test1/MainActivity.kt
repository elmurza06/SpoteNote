package com.example.flutter_application_test1

import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Нативная часть SpotNote: работа с NFC через platform channel "spotnote/nfc".
 *
 * Логика как у ссылок на папки: на метку пишется только ссылка
 * `spotnote://list/<id>`, а сам список хранится файлом на телефоне.
 *
 * - Пока приложение открыто, включён reader mode: каждое касание метки
 *   либо записывает ссылку (если идёт запись), либо читает её и отправляет во Flutter.
 * - Если приложение закрыто, Android сам открывает его по метке
 *   (intent-filter NDEF_DISCOVERED + Android Application Record).
 *
 * Методы для Dart: getStatus, getInitialLink, startWrite(uri), cancelWrite, openSettings.
 * События в Dart: onTap({link}) — касание метки или открытие по ссылке.
 */
class MainActivity : FlutterActivity(), NfcAdapter.ReaderCallback {

    private var channel: MethodChannel? = null
    private var nfcAdapter: NfcAdapter? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Ссылка, по которой приложение было запущено (холодный старт от метки). */
    private var initialLink: String? = null

    /** Если не null — следующая приложенная метка будет записана этой ссылкой. */
    @Volatile
    private var pendingWriteUri: String? = null
    private var pendingWriteResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        initialLink = extractLink(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus" -> result.success(status())

                "getInitialLink" -> {
                    result.success(initialLink)
                    initialLink = null
                }

                "startWrite" -> {
                    val uri = call.argument<String>("uri")
                    when {
                        uri.isNullOrBlank() ->
                            result.error("bad_args", "uri is required", null)
                        status() != "enabled" ->
                            result.error("nfc_unavailable", status(), null)
                        else -> {
                            // Отменяем предыдущую незавершённую запись, если была.
                            finishWrite { it.error("cancelled", "Replaced by a new write", null) }
                            pendingWriteResult = result
                            pendingWriteUri = uri
                        }
                    }
                }

                "cancelWrite" -> {
                    finishWrite { it.error("cancelled", "Cancelled by user", null) }
                    result.success(null)
                }

                "openSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                    } catch (ignored: Exception) {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
        channel = ch
    }

    override fun onResume() {
        super.onResume()
        val adapter = nfcAdapter ?: return
        if (!adapter.isEnabled) return
        try {
            adapter.enableReaderMode(
                this,
                this,
                NfcAdapter.FLAG_READER_NFC_A or
                        NfcAdapter.FLAG_READER_NFC_B or
                        NfcAdapter.FLAG_READER_NFC_F or
                        NfcAdapter.FLAG_READER_NFC_V,
                null,
            )
        } catch (ignored: Exception) {
            // На некоторых устройствах reader mode недоступен — тогда работают intent'ы.
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            nfcAdapter?.disableReaderMode(this)
        } catch (ignored: Exception) {
        }
    }

    /** Приложение уже запущено, а Android передал ему метку или ссылку. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val link = extractLink(intent) ?: return
        channel?.invokeMethod("onTap", mapOf("link" to link))
    }

    /** Вызывается в фоновом потоке, когда к телефону приложили метку (reader mode). */
    override fun onTagDiscovered(tag: Tag) {
        val uri = pendingWriteUri
        if (uri != null) {
            val error = writeTag(tag, uri)
            val tagId = tag.id?.joinToString("") { "%02X".format(it) } ?: ""
            mainHandler.post {
                finishWrite { result ->
                    if (error == null) {
                        result.success(tagId)
                    } else {
                        result.error(error.first, error.second, null)
                    }
                }
            }
        } else {
            val link = readLink(tag)
            mainHandler.post {
                channel?.invokeMethod("onTap", mapOf("link" to link))
            }
        }
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private fun status(): String {
        val adapter = nfcAdapter ?: return "unsupported"
        return if (adapter.isEnabled) "enabled" else "disabled"
    }

    /** Достаёт ссылку из intent'а, которым открыли приложение (метка или adb/браузер). */
    private fun extractLink(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            NfcAdapter.ACTION_NDEF_DISCOVERED, Intent.ACTION_VIEW -> intent.data?.toString()
            else -> null
        }
    }

    private fun finishWrite(block: (MethodChannel.Result) -> Unit) {
        val result = pendingWriteResult
        pendingWriteResult = null
        pendingWriteUri = null
        if (result != null) block(result)
    }

    /** Сообщение на метке: ссылка на список + запись «открыть приложение SpotNote». */
    private fun buildMessage(uri: String): NdefMessage = NdefMessage(
        arrayOf(
            NdefRecord.createUri(uri),
            NdefRecord.createApplicationRecord(packageName),
        ),
    )

    /** Возвращает null при успехе или пару (код ошибки, описание). */
    private fun writeTag(tag: Tag, uri: String): Pair<String, String>? {
        val message = buildMessage(uri)
        try {
            val ndef = Ndef.get(tag)
            if (ndef != null) {
                ndef.connect()
                try {
                    if (!ndef.isWritable) return "read_only" to "Tag is read-only"
                    if (ndef.maxSize < message.byteArrayLength) {
                        return "too_small" to "Tag holds ${ndef.maxSize} bytes, need ${message.byteArrayLength}"
                    }
                    ndef.writeNdefMessage(message)
                } finally {
                    try { ndef.close() } catch (ignored: Exception) {}
                }
                return null
            }

            // Новая, ещё не размеченная метка — форматируем её сразу с нашим сообщением.
            val formatable = NdefFormatable.get(tag)
                ?: return "not_ndef" to "Tag does not support NDEF"
            formatable.connect()
            try {
                formatable.format(message)
            } finally {
                try { formatable.close() } catch (ignored: Exception) {}
            }
            return null
        } catch (e: Exception) {
            return "io_error" to (e.message ?: e.javaClass.simpleName)
        }
    }

    /** Первая URI-запись на метке или null, если её нет (пустая/чужая метка). */
    private fun readLink(tag: Tag): String? {
        val message = Ndef.get(tag)?.cachedNdefMessage ?: return null
        for (record in message.records) {
            val uri = record.toUri() ?: continue
            return uri.toString()
        }
        return null
    }

    companion object {
        private const val CHANNEL = "spotnote/nfc"
    }
}
package com.taskearning.earning.money.app.keyboard

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.taskearning.earning.money.app.R
import kotlinx.coroutines.*
import kotlin.random.Random

class TaskReviewInputMethodService : InputMethodService() {

    private var rootView: View? = null
    private var isShifted = false
    private var isSymbolMode = false
    private var isTyping = false
    private var typingJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private var activeReviewText: String? = null
    private var activePlatform: String? = null
    private var activeTaskId: String? = null

    private lateinit var tvBadge: TextView
    private lateinit var tvPreview: TextView
    private lateinit var btnWriteReview: Button
    private lateinit var btnStopReview: Button
    private lateinit var btnPasteReview: Button
    private lateinit var reviewActionBar: LinearLayout
    private lateinit var row1: LinearLayout
    private lateinit var row2: LinearLayout
    private lateinit var row3Letters: LinearLayout
    private lateinit var btnShift: Button
    private lateinit var btnBackspace: Button
    private lateinit var btnSymbols: Button
    private lateinit var btnSwitchIme: Button
    private lateinit var btnSpace: Button
    private lateinit var btnPeriod: Button
    private lateinit var btnEnter: Button

    private val letterRow1 = listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
    private val letterRow2 = listOf("a", "s", "d", "f", "g", "h", "j", "k", "l")
    private val letterRow3 = listOf("z", "x", "c", "v", "b", "n", "m")

    private val symbolRow1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
    private val symbolRow2 = listOf("@", "#", "$", "%", "&", "-", "+", "(", ")")
    private val symbolRow3 = listOf("*", "\"", "'", ":", ";", "!", "?")

    override fun onCreateInputView(): View {
        val inflater = LayoutInflater.from(this)
        rootView = inflater.inflate(R.layout.keyboard_view, null)

        initViews(rootView!!)
        loadActiveReviewFromPrefs()
        setupListeners()
        renderKeyboardKeys()
        updateReviewBarUi()

        return rootView!!
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        loadActiveReviewFromPrefs()
        updateReviewBarUi()
    }

    private fun initViews(view: View) {
        tvBadge = view.findViewById(R.id.tv_review_badge)
        tvPreview = view.findViewById(R.id.tv_review_preview)
        btnWriteReview = view.findViewById(R.id.btn_write_review)
        btnStopReview = view.findViewById(R.id.btn_stop_review)
        btnPasteReview = view.findViewById(R.id.btn_paste_review)
        reviewActionBar = view.findViewById(R.id.review_action_bar)

        row1 = view.findViewById(R.id.row_1)
        row2 = view.findViewById(R.id.row_2)
        row3Letters = view.findViewById(R.id.row_3_letters)

        btnShift = view.findViewById(R.id.btn_shift)
        btnBackspace = view.findViewById(R.id.btn_backspace)
        btnSymbols = view.findViewById(R.id.btn_symbols)
        btnSwitchIme = view.findViewById(R.id.btn_switch_ime)
        btnSpace = view.findViewById(R.id.btn_space)
        btnPeriod = view.findViewById(R.id.btn_period)
        btnEnter = view.findViewById(R.id.btn_enter)
    }

    private fun getPrefs(): SharedPreferences {
        return getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private fun loadActiveReviewFromPrefs() {
        val prefs = getPrefs()
        activeReviewText = prefs.getString("flutter.active_review_text", null)
            ?: prefs.getString("active_review_text", null)
        activePlatform = prefs.getString("flutter.active_platform", null)
            ?: prefs.getString("active_platform", null)
        activeTaskId = prefs.getString("flutter.active_task_id", null)
            ?: prefs.getString("active_task_id", null)
    }

    private fun updateReviewBarUi() {
        val review = activeReviewText?.trim()
        val platform = activePlatform?.lowercase() ?: ""

        val isGoogle = platform.contains("google") || platform.contains("maps") || platform.contains("business")
        val isPlay = platform.contains("play") || platform.contains("app")

        if (!review.isNullOrEmpty() && (isGoogle || isPlay)) {
            reviewActionBar.visibility = View.VISIBLE
            btnWriteReview.visibility = if (isTyping) View.GONE else View.VISIBLE
            btnPasteReview.visibility = if (isTyping) View.GONE else View.VISIBLE
            btnStopReview.visibility = if (isTyping) View.VISIBLE else View.GONE

            if (isGoogle) {
                tvBadge.text = "⭐ Google Maps Review Ready"
                tvBadge.setTextColor(Color.parseColor("#38BDF8"))
            } else {
                tvBadge.text = "📱 Play Store Review Ready"
                tvBadge.setTextColor(Color.parseColor("#34D399"))
            }

            tvPreview.text = if (isTyping) "✍️ Auto-typing into review box..." else review
        } else {
            // Non-review task: keep action bar clean
            tvBadge.text = "⌨️ Task Review Keyboard"
            tvBadge.setTextColor(Color.parseColor("#94A3B8"))
            tvPreview.text = "Ready to type"
            btnWriteReview.visibility = View.GONE
            btnPasteReview.visibility = View.GONE
            btnStopReview.visibility = View.GONE
        }
    }

    private fun setupListeners() {
        // Write Review (Auto-Typing Simulation)
        btnWriteReview.setOnClickListener {
            val text = activeReviewText
            if (!text.isNullOrBlank()) {
                startAutoTyping(text)
            }
        }

        // Stop Auto-Typing
        btnStopReview.setOnClickListener {
            stopAutoTyping()
        }

        // Quick Instant Paste
        btnPasteReview.setOnClickListener {
            val text = activeReviewText
            if (!text.isNullOrBlank()) {
                currentInputConnection?.commitText(text, 1)
            }
        }

        // Shift / Caps Key
        btnShift.setOnClickListener {
            if (!isSymbolMode) {
                isShifted = !isShifted
                btnShift.text = if (isShifted) "⇪" else "⇧"
                renderKeyboardKeys()
            }
        }

        // Symbol Mode Toggle (?123 / ABC)
        btnSymbols.setOnClickListener {
            isSymbolMode = !isSymbolMode
            btnSymbols.text = if (isSymbolMode) "ABC" else "?123"
            btnShift.visibility = if (isSymbolMode) View.INVISIBLE else View.VISIBLE
            renderKeyboardKeys()
        }

        // Backspace with repeat handler
        btnBackspace.setOnClickListener {
            handleBackspace()
        }
        setupBackspaceHold(btnBackspace)

        // Spacebar
        btnSpace.setOnClickListener {
            currentInputConnection?.commitText(" ", 1)
        }

        // Period
        btnPeriod.setOnClickListener {
            currentInputConnection?.commitText(".", 1)
        }

        // Enter / Done
        btnEnter.setOnClickListener {
            val ic = currentInputConnection ?: return@setOnClickListener
            val editorInfo = currentInputEditorInfo
            val action = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE

            when (action) {
                EditorInfo.IME_ACTION_GO,
                EditorInfo.IME_ACTION_NEXT,
                EditorInfo.IME_ACTION_SEARCH,
                EditorInfo.IME_ACTION_SEND,
                EditorInfo.IME_ACTION_DONE -> {
                    ic.performEditorAction(action)
                }
                else -> {
                    ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
                    ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
                }
            }
        }

        // Switch to System Keyboard (🌐)
        btnSwitchIme.setOnClickListener {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                switchToPreviousInputMethod()
            } else {
                imm?.showInputMethodPicker()
            }
        }
    }

    private fun handleBackspace() {
        val ic = currentInputConnection ?: return
        val selectedText = ic.getSelectedText(0)
        if (selectedText.isNullOrEmpty()) {
            ic.deleteSurroundingText(1, 0)
        } else {
            ic.commitText("", 1)
        }
    }

    private fun setupBackspaceHold(button: Button) {
        val handler = Handler(Looper.getMainLooper())
        val deleteRunnable = object : Runnable {
            override fun run() {
                handleBackspace()
                handler.postDelayed(this, 60)
            }
        }

        button.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    handleBackspace()
                    handler.postDelayed(deleteRunnable, 400)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    handler.removeCallbacks(deleteRunnable)
                    true
                }
                else -> false
            }
        }
    }

    private fun renderKeyboardKeys() {
        val r1Keys = if (isSymbolMode) symbolRow1 else letterRow1
        val r2Keys = if (isSymbolMode) symbolRow2 else letterRow2
        val r3Keys = if (isSymbolMode) symbolRow3 else letterRow3

        populateRow(row1, r1Keys, 10)
        populateRow(row2, r2Keys, 9)
        populateRow(row3Letters, r3Keys, 7)
    }

    private fun populateRow(container: LinearLayout, keys: List<String>, weightSum: Int) {
        container.removeAllViews()
        container.weightSum = weightSum.toFloat()

        for (k in keys) {
            val charToDisplay = if (!isSymbolMode && isShifted) k.uppercase() else k
            val keyButton = Button(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1.0f).apply {
                    setMargins(2, 0, 2, 0)
                }
                text = charToDisplay
                textSize = 17f
                setTextColor(Color.parseColor("#0F172A"))
                setBackgroundResource(R.drawable.key_background)
                setPadding(0, 0, 0, 0)
                minWidth = 0
                minHeight = 0
                isAllCaps = false

                setOnClickListener {
                    currentInputConnection?.commitText(charToDisplay, 1)
                    if (isShifted && !isSymbolMode) {
                        isShifted = false
                        btnShift.text = "⇧"
                        renderKeyboardKeys()
                    }
                }
            }
            container.addView(keyButton)
        }
    }

    private fun startAutoTyping(review: String) {
        if (isTyping) return
        isTyping = true
        updateReviewBarUi()

        typingJob = serviceScope.launch {
            val ic = currentInputConnection
            if (ic == null) {
                stopAutoTyping()
                return@launch
            }

            for (i in review.indices) {
                if (!isActive || !isTyping) break
                val c = review[i]
                ic.commitText(c.toString(), 1)

                // Human keystroke simulation delay (28ms - 45ms, extra for punctuation/spaces)
                val baseDelay = when (c) {
                    ' ', ',', '.' -> Random.nextLong(65, 110)
                    '!', '?' -> Random.nextLong(90, 140)
                    else -> Random.nextLong(28, 48)
                }
                delay(baseDelay)
            }

            isTyping = false
            btnWriteReview.text = "✓ Finished"
            updateReviewBarUi()

            delay(2000)
            btnWriteReview.text = "✍️ Write Review"
            updateReviewBarUi()
        }
    }

    private fun stopAutoTyping() {
        isTyping = false
        typingJob?.cancel()
        typingJob = null
        btnWriteReview.text = "✍️ Write Review"
        updateReviewBarUi()
    }

    override fun onDestroy() {
        super.onDestroy()
        typingJob?.cancel()
        serviceScope.cancel()
    }
}

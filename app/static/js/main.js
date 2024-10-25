// Timer functionality
let timerInterval;
let timeSpent = 0;

function startTimer() {
    const timerDisplay = document.getElementById('timer');
    if (timerDisplay && !timerInterval) {
        timerInterval = setInterval(() => {
            timeSpent++;
            const minutes = Math.floor(timeSpent / 60);
            const seconds = timeSpent % 60;
            timerDisplay.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        }, 1000);
    }
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
        const focusTimeInput = document.getElementById('focus_time');
        if (focusTimeInput) {
            focusTimeInput.value = Math.floor(timeSpent / 60);
        }
    }
}

// Focus mode toggle
function toggleFocusMode() {
    document.body.classList.toggle('focus-mode');
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    const textarea = document.querySelector('textarea');
    if (textarea) {
        textarea.addEventListener('focus', startTimer);
        textarea.addEventListener('blur', stopTimer);
    }
});

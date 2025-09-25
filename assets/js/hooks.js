// Task value calculator hook
const TaskCalculator = {
  mounted() {
    this.calculateTaskValue();
    this.el.addEventListener("input", () => this.calculateTaskValue());
  },

  updated() {
    this.calculateTaskValue();
  },

  calculateTaskValue() {
    const ratePerHourInput = document.getElementById("rate_per_hour");
    const audioLengthInput = document.getElementById("audio_length_minutes");
    const taskValueInput = document.getElementById("task_value_dollars");

    if (ratePerHourInput && audioLengthInput && taskValueInput) {
      const ratePerHour = parseFloat(ratePerHourInput.value) || 0;
      const audioLength = parseFloat(audioLengthInput.value) || 0;

      // Formula: task_value = rate_per_hour / 60 * audio_length
      const taskValue = (ratePerHour / 60) * audioLength;

      taskValueInput.value = taskValue.toFixed(2);
    }
  }
};

export { TaskCalculator };
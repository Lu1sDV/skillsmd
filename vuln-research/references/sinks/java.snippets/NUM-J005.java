double val = Double.valueOf(userInput); // "Infinity"
if (val >= Double.MAX_VALUE - currentBalance) { // Infinity >= anything = false
    throw new IllegalArgumentException(); // NEVER THROWS
}
currentBalance += val; // Infinity → balance corrupted forever

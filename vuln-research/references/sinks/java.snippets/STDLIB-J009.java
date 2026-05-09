Pattern p = Pattern.compile("(a+)+b"); // exponential
p.matcher("aaaaaaaaaaaaaaaaaaaaaaaa!").matches(); // hangs on JDK 8

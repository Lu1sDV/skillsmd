BigDecimal giant = new BigDecimal("9999999e99999999"); // 10M digits
giant.add(BigDecimal.ONE); // CPU DoS

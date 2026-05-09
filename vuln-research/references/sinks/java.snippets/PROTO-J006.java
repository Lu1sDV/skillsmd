HttpURLConnection conn = (HttpURLConnection) url.openConnection();
// conn.setInstanceFollowRedirects(false); // MISSING!
// Initial URL passes host check → gets 302 → follows to internal address

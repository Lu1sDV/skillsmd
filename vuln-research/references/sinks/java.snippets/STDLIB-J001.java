// Beans.instantiate first deserializes "x/y.ser", then loads class "x.y"
Object bean = Beans.instantiate(null, attackerControlledBeanName);
// Internally: 1) resource path "x/y.ser" → ObjectInputStream.readObject()
//             2) fallback: Class.forName("x.y").newInstance()

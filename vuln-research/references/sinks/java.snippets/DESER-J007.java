Descriptor desc = new DescriptorSupport();
desc.setField("class", "java.lang.System");  // target class
desc.setField("role", "operation");
ModelMBeanOperationInfo opInfo = new ModelMBeanOperationInfo(
    "setProperty", null, new MBeanParameterInfo[]{...},
    "void", MBeanOperationInfo.ACTION, desc);
// Invoking "setProperty" calls System.setProperty() statically

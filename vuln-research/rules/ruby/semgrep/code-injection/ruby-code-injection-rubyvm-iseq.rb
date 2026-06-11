# Fixture for the RubyVM InstructionSequence rule.
# Compiling/eval'ing dynamic source or serialized bytecode is flagged.

def run(params)
  # ruleid: ruby-code-injection-rubyvm-iseq
  RubyVM::InstructionSequence.compile(params[:src]).eval
end

def run_blob(data)
  # ruleid: ruby-code-injection-rubyvm-iseq
  RubyVM::InstructionSequence.load_from_binary(data).eval
end

def safe_compile
  # ok: ruby-code-injection-rubyvm-iseq
  RubyVM::InstructionSequence.compile("1 + 1").to_a
end

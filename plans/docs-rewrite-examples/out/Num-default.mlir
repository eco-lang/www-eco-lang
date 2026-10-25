module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 30 : i64} : () -> i64 
        %1 = "arith.constant"() {value = 30.0 : f64} : () -> f64 
        %8 = "arith.constant"() {value = 10 : i64} : () -> i64 
        %9 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %2 = "eco.int.add"(%8, %9) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %11 = "arith.constant"() {value = 1.5 : f64} : () -> f64 
        %3 = "eco.float.mul"(%1, %11) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
        %13 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %4 = "eco.int.add"(%0, %13) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %15 = "eco.string.from_int"(%4) {_operand_types = [i64]} : (i64) -> !eco.value 
        %16 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %17 = "eco.string.from_float"(%3) {_operand_types = [f64]} : (f64) -> !eco.value 
        %18 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %19 = "eco.box"(%2) {_operand_types = [i64]} : (i64) -> !eco.value 
        %20 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %21 = "eco.call"(%19, %20) <{_operand_types = [!eco.value, i64], callee = @Elm_Kernel_Debug_toString_typed}> : (!eco.value, i64) -> !eco.value 
        %22 = "eco.string.append"(%18, %21) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %23 = "eco.string.append"(%17, %22) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %24 = "eco.string.append"(%16, %23) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %5 = "eco.string.append"(%15, %24) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %26 = "eco.call"(%5) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%26) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Num_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Num_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Debug_toString_typed", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [], func_args = [], strings = [], types = [[0, 0, 0]]} : () -> () 
} 

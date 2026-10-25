module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 30 : i64} : () -> i64 
        %1 = "arith.constant"() {value = 30.0 : f64} : () -> f64 
        %7 = "arith.constant"() {value = 10 : i64} : () -> i64 
        %8 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %2 = "eco.int.add"(%7, %8) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %10 = "arith.constant"() {value = 1.5 : f64} : () -> f64 
        %3 = "eco.float.mul"(%1, %10) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
        %12 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %4 = "eco.int.add"(%0, %12) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %14 = "eco.string.from_int"(%4) {_operand_types = [i64]} : (i64) -> !eco.value 
        %15 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %16 = "eco.string.from_float"(%3) {_operand_types = [f64]} : (f64) -> !eco.value 
        %17 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %18 = "eco.box"(%2) {_operand_types = [i64]} : (i64) -> !eco.value 
        %19 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %20 = "eco.call"(%18, %19) <{_operand_types = [!eco.value, i64], callee = @Elm_Kernel_Debug_toString_typed}> : (!eco.value, i64) -> !eco.value 
        %21 = "eco.call"(%17, %20) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_1}> : (!eco.value, !eco.value) -> !eco.value 
        %22 = "eco.call"(%16, %21) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_1}> : (!eco.value, !eco.value) -> !eco.value 
        %23 = "eco.call"(%15, %22) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_1}> : (!eco.value, !eco.value) -> !eco.value 
        %24 = "eco.call"(%14, %23) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_1}> : (!eco.value, !eco.value) -> !eco.value 
        %25 = "eco.call"(%24) <{_operand_types = [!eco.value], callee = @Html_text_$_2}> : (!eco.value) -> !eco.value 
        "eco.return"(%25) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Num_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.call"(%arg0, %arg1) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Utils_append, eco.cse_safe}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Basics_append_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_eta114: !eco.value):
        %1 = "eco.call"(%_eta114) <{_operand_types = [!eco.value], callee = @VirtualDom_text_$_3}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Html_text_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.call"(%arg0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "VirtualDom_text_$_3", sym_visibility = "private"} : () -> () 
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
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Utils_append", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [], func_args = [], strings = [], types = [[0, 0, 0]]} : () -> () 
} 

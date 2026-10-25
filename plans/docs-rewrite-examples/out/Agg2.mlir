module {
  "func.func"() ({
        %1 = "arith.constant"() {value = 17 : i64} : () -> i64 
        %2 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %3, %4 = "eco.call"(%1, %2) <{_operand_types = [i64, i64], callee = @Agg2_divMod_$_1$sret}> : (i64, i64) -> (i64, i64) 
        %5 = "eco.make.tuple2"(%3, %4) {_operand_types = [i64, i64]} : (i64, i64) -> !eco.tuple2<i64, i64> 
        %7 = "eco.project.tuple2"(%5) {_operand_types = [!eco.tuple2<i64, i64>], field = 0} : (!eco.tuple2<i64, i64>) -> i64 
        %8 = "eco.project.tuple2"(%5) {_operand_types = [!eco.tuple2<i64, i64>], field = 1} : (!eco.tuple2<i64, i64>) -> i64 
        %9 = "eco.call"(%7, %8) <{_operand_types = [i64, i64], callee = @Agg2_magnitude_$_2$psplit}> : (i64, i64) -> i64 
        %10 = "eco.string.from_int"(%9) {_operand_types = [i64]} : (i64) -> !eco.value 
        %11 = "eco.call"(%10) <{_operand_types = [!eco.value], callee = @Html_text_$_3}> : (!eco.value) -> !eco.value 
        "eco.return"(%11) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Agg2_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%a: i64, %b: i64):
        %2 = "eco.int.div"(%a, %b) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %3 = "eco.int.modby"(%b, %a) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %4 = "eco.make.tuple2"(%2, %3) {_operand_types = [i64, i64]} : (i64, i64) -> !eco.tuple2<i64, i64> 
        %5 = "eco.project.tuple2"(%4) {_operand_types = [!eco.tuple2<i64, i64>], field = 0} : (!eco.tuple2<i64, i64>) -> i64 
        %6 = "eco.project.tuple2"(%4) {_operand_types = [!eco.tuple2<i64, i64>], field = 1} : (!eco.tuple2<i64, i64>) -> i64 
        "eco.return"(%5, %6) {_operand_types = [i64, i64]} : (i64, i64) -> () 
  }) {function_type = (i64, i64) -> (i64, i64), sym_name = "Agg2_divMod_$_1$sret", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%a: i64, %b: i64):
        %2, %3 = "eco.call"(%a, %b) <{_operand_types = [i64, i64], callee = @Agg2_divMod_$_1$sret}> : (i64, i64) -> (i64, i64) 
        %4 = "eco.construct.tuple2"(%2, %3) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["tuple2:i:i"], function_type = (i64, i64) -> (!eco.value), sym_name = "Agg2_divMod_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0_s0: i64, %_v0_s1: i64):
        %2 = "eco.int.mul"(%_v0_s0, %_v0_s0) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %3 = "eco.int.mul"(%_v0_s1, %_v0_s1) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %4 = "eco.int.add"(%2, %3) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%4) {_operand_types = [i64]} : (i64) -> () 
  }) {function_type = (i64, i64) -> (i64), sym_name = "Agg2_magnitude_$_2$psplit", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: !eco.value):
        %1 = "eco.project.tuple2"(%_v0) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %2 = "eco.project.tuple2"(%_v0) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %3 = "eco.call"(%1, %2) <{_operand_types = [i64, i64], callee = @Agg2_magnitude_$_2$psplit}> : (i64, i64) -> i64 
        "eco.return"(%3) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["tuple2:i:i"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "Agg2_magnitude_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_eta114: !eco.value):
        %1 = "eco.call"(%_eta114) <{_operand_types = [!eco.value], callee = @VirtualDom_text_$_4}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Html_text_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.call"(%arg0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "VirtualDom_text_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Agg2_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [[0, 0], [0, 0]], func_args = [], strings = [], types = [[0, 0, 0], [1, 2, 2, 0, 2]]} : () -> () 
} 

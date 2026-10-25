module {
  "func.func"() ({
        %2 = "arith.constant"() {value = 2.0 : f64} : () -> f64 
        %3 = "arith.constant"() {value = 1.0 : f64} : () -> f64 
        %4 = "arith.constant"() {value = 2.0 : f64} : () -> f64 
        %5 = "eco.construct.custom"(%3, %4) {_operand_types = [f64, f64], constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value 
        %0 = "eco.call"(%2, %5) <{_operand_types = [f64, !eco.value], callee = @Scale_scale_$_2}> : (f64, !eco.value) -> !eco.value 
        %7 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %10 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %8 = "eco.construct.custom"(%10) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        %12 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %13 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %14 = "arith.cmpi"(%12, %13) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %18 = "eco.case"(%14) ({
              %16 = "eco.project.custom"(%8) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              %17 = "eco.int.add"(%7, %16) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
              "eco.yield"(%17) {_operand_types = [i64]} : (i64) -> () 
        }, {
              "eco.yield"(%7) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        %19 = "eco.string.from_int"(%18) {_operand_types = [i64]} : (i64) -> !eco.value 
        %20 = "eco.get_tag"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %21 = "arith.constant"() {value = 1 : i32} : () -> i32 
        %22 = "arith.cmpi"(%20, %21) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %29 = "eco.case"(%22) ({
              %24 = "eco.project.custom"(%0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %25 = "eco.string.from_float"(%24) {_operand_types = [f64]} : (f64) -> !eco.value 
              "eco.yield"(%25) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %27 = "eco.project.custom"(%0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %28 = "eco.string.from_float"(%27) {_operand_types = [f64]} : (f64) -> !eco.value 
              "eco.yield"(%28) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        %1 = "eco.string.append"(%19, %29) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %31 = "eco.call"(%1) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%31) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Scale_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: f64, %arg1: f64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [f64, f64], constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (f64, f64) -> (!eco.value), sym_name = "Scale_Rect_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%k: f64, %shape: !eco.value):
        %2 = "eco.get_tag"(%shape) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %3 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %4 = "arith.cmpi"(%2, %3) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %16 = "eco.case"(%4) ({
              %6 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %7 = "eco.float.mul"(%k, %6) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              %8 = "eco.construct.custom"(%7) {_operand_types = [f64], constructor = "Circle", size = 1, slot_kinds = array<i8: 2>, tag = 0} : (f64) -> !eco.value 
              "eco.yield"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %10 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %12 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> f64 
              %13 = "eco.float.mul"(%k, %10) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              %14 = "eco.float.mul"(%k, %12) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              %15 = "eco.construct.custom"(%13, %14) {_operand_types = [f64, f64], constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value 
              "eco.yield"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["f64", "value"], eco.logical_result_types = ["value"], function_type = (f64, !eco.value) -> (!eco.value), sym_name = "Scale_scale_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Maybe_Just_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: f64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [f64], constructor = "Circle", size = 1, slot_kinds = array<i8: 2>, tag = 0} : (f64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (f64) -> (!eco.value), sym_name = "Scale_Circle_$_8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Scale_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 0, 0, 1], [1, 2, 1, 2], [0, 4, 3, 1], [1, 5, 4, 0]], fields = [[1, 0], [1, 0], [3, 0], [1, 2]], func_args = [], strings = ["Circle", "field0", "Rect", "field1", "Just", "Nothing"], types = [[0, 0, 1], [1, 4, 0, 2], [2, 0, 0], [3, 4, 2, 2]]} : () -> () 
} 

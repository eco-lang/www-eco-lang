module {
  "func.func"() ({
        %2 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %3 = "arith.constant"() {value = 4 : i64} : () -> i64 
        %0 = "eco.make.tuple2"(%2, %3) {_operand_types = [i64, i64]} : (i64, i64) -> !eco.tuple2<i64, i64> 
        %5 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %6 = "arith.constant"() {value = 9 : i64} : () -> i64 
        %7 = "eco.construct.list"(%6, %5) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %8 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %9 = "eco.construct.list"(%8, %7) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %10 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %11 = "eco.construct.list"(%10, %9) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %1 = "eco.call"(%11) <{_operand_types = [!eco.value], callee = @Agg_minMax_$_1}> : (!eco.value) -> !eco.value 
        %14 = "eco.project.tuple2"(%1) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %16 = "eco.project.tuple2"(%1) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %19 = "eco.project.tuple2"(%0) {_operand_types = [!eco.tuple2<i64, i64>], field = 0} : (!eco.tuple2<i64, i64>) -> i64 
        %21 = "eco.project.tuple2"(%0) {_operand_types = [!eco.tuple2<i64, i64>], field = 1} : (!eco.tuple2<i64, i64>) -> i64 
        %22 = "eco.int.mul"(%19, %21) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %23 = "eco.int.add"(%22, %14) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %24 = "eco.int.add"(%23, %16) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %25 = "eco.string.from_int"(%24) {_operand_types = [i64]} : (i64) -> !eco.value 
        %26 = "eco.call"(%25) <{_operand_types = [!eco.value], callee = @Html_text_$_2}> : (!eco.value) -> !eco.value 
        "eco.return"(%26) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Agg_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value):
        %1 = "eco.papCreate"() {arity = 2, function = @_tail_mono_inline_0_22, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = 999 : i64} : () -> i64 
        %4 = "arith.constant"() {value = 999 : i64} : () -> i64 
        %5 = "eco.int.negate"(%4) {_operand_types = [i64]} : (i64) -> i64 
        %6 = "eco.construct.tuple2"(%3, %5) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
        %7 = "eco.papExtend"(%1, %6, %xs) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value) -> (!eco.value), sym_name = "Agg_minMax_$_1", sym_visibility = "private"} : () -> () 
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
      ^bb0(%x: i64, %y: i64):
        %2 = "eco.int.lt"(%x, %y) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
        %3 = "eco.case"(%2) ({
              "eco.yield"(%x) {_operand_types = [i64]} : (i64) -> () 
        }, {
              "eco.yield"(%y) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        "eco.return"(%3) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64) -> (i64), sym_name = "Basics_min_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64, %y: i64):
        %2 = "eco.int.gt"(%x, %y) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
        %3 = "eco.case"(%2) ({
              "eco.yield"(%x) {_operand_types = [i64]} : (i64) -> () 
        }, {
              "eco.yield"(%y) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        "eco.return"(%3) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64) -> (i64), sym_name = "Basics_max_$_5", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_2: !eco.value, %mono_inline_3: !eco.value):
        %2 = "eco.papCreate"() {arity = 2, function = @_tail_mono_inline_0_22, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8 = "scf.while"(%mono_inline_2, %mono_inline_3, %3, %4) ({
            ^bb0(%9: !eco.value, %10: !eco.value, %11: i1, %12: !eco.value):
              %14 = "arith.constant"() {value = true} : () -> i1 
              %13 = "arith.xori"(%11, %14) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%13, %9, %10, %11, %12) {_operand_types = [i1, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%15: !eco.value, %16: !eco.value, %17: i1, %18: !eco.value):
              %19 = "eco.get_tag"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %20 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %21 = "arith.cmpi"(%19, %20) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %36, %37, %38, %39 = "eco.case"(%21) ({
                    %22 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%15, %16, %22, %15) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %23 = "eco.project.list_head"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %24 = "eco.project.list_tail"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
                    %30 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
                    %31 = "eco.int.min"(%28, %23) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %32 = "eco.int.max"(%30, %23) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %33 = "eco.construct.tuple2"(%31, %32) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
                    %34 = "arith.constant"() {value = false} : () -> i1 
                    %35 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%33, %24, %34, %35) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%36, %37, %38, %39) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["tuple2:i:i", "cons:i:v"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "_tail_mono_inline_0_22", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Agg_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [[0, 0], [0, 0]], func_args = [], strings = [], types = [[0, 0, 0], [1, 2, 2, 0, 2], [2, 1, 0]]} : () -> () 
} 

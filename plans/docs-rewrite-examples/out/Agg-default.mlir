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
        %23 = "eco.int.mul"(%19, %21) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %24 = "eco.int.add"(%23, %14) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %25 = "eco.int.add"(%24, %16) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %22 = "eco.string.from_int"(%25) {_operand_types = [i64]} : (i64) -> !eco.value 
        %27 = "eco.call"(%22) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Agg_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value):
        %1 = "eco.papCreate"() {arity = 2, function = @_tail_mono_inline_1_22, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = 999 : i64} : () -> i64 
        %4 = "arith.constant"() {value = 999 : i64} : () -> i64 
        %5 = "eco.int.negate"(%4) {_operand_types = [i64]} : (i64) -> i64 
        %6 = "eco.construct.tuple2"(%3, %5) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
        %7 = "eco.papExtend"(%1, %6, %xs) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value) -> (!eco.value), sym_name = "Agg_minMax_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_3: !eco.value, %mono_inline_4: !eco.value):
        %2 = "eco.papCreate"() {arity = 2, function = @_tail_mono_inline_1_22, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8 = "scf.while"(%mono_inline_3, %mono_inline_4, %3, %4) ({
            ^bb0(%9: !eco.value, %10: !eco.value, %11: i1, %12: !eco.value):
              %14 = "arith.constant"() {value = true} : () -> i1 
              %13 = "arith.xori"(%11, %14) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%13, %9, %10, %11, %12) {_operand_types = [i1, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%15: !eco.value, %16: !eco.value, %17: i1, %18: !eco.value):
              %19 = "eco.get_tag"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %20 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %21 = "arith.cmpi"(%19, %20) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %42, %43, %44, %45 = "eco.case"(%21) ({
                    %22 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%15, %16, %22, %15) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %23 = "eco.project.list_head"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %24 = "eco.project.list_tail"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
                    %30 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
                    %33 = "eco.int.lt"(%28, %23) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                    %34 = "eco.case"(%33) ({
                          "eco.yield"(%28) {_operand_types = [i64]} : (i64) -> () 
                    }, {
                          "eco.yield"(%23) {_operand_types = [i64]} : (i64) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
                    %37 = "eco.int.gt"(%30, %23) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                    %38 = "eco.case"(%37) ({
                          "eco.yield"(%30) {_operand_types = [i64]} : (i64) -> () 
                    }, {
                          "eco.yield"(%23) {_operand_types = [i64]} : (i64) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
                    %39 = "eco.construct.tuple2"(%34, %38) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
                    %40 = "arith.constant"() {value = false} : () -> i1 
                    %41 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%39, %24, %40, %41) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%42, %43, %44, %45) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["tuple2:i:i", "cons:i:v"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "_tail_mono_inline_1_22", sym_visibility = "private"} : () -> () 
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

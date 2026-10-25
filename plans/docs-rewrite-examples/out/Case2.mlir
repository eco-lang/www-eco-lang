module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %1 = "eco.construct.custom"(%0) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        %2 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %3 = "eco.construct.custom"(%2) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        %4 = "eco.call"(%1, %3) <{_operand_types = [!eco.value, !eco.value], callee = @Case2_classify_$_2}> : (!eco.value, !eco.value) -> !eco.value 
        %5 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %6 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %7 = "eco.call"(%5, %6) <{_operand_types = [!eco.value, !eco.value], callee = @Case2_classify_$_2}> : (!eco.value, !eco.value) -> !eco.value 
        %8 = "eco.call"(%4, %7) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_4}> : (!eco.value, !eco.value) -> !eco.value 
        %9 = "eco.call"(%8) <{_operand_types = [!eco.value], callee = @Html_text_$_5}> : (!eco.value) -> !eco.value 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Case2_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Maybe_Just_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%a: !eco.value, %b: !eco.value):
        %2 = "eco.construct.tuple2"(%a, %b) {_operand_types = [!eco.value, !eco.value], unboxed_bitmap = 0} : (!eco.value, !eco.value) -> !eco.value 
        %5 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> !eco.value 
        %6 = "eco.get_tag"(%5) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %7 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %8 = "arith.cmpi"(%6, %7) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %49 = "eco.case"(%8) ({
              %10 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> !eco.value 
              %12 = "eco.project.custom"(%10) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              %13 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %14 = "eco.int.eq"(%12, %13) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
              %32 = "eco.case"(%14) ({
                    %15 = "eco.string_literal"() {value = "a is zero"} : () -> !eco.value 
                    "eco.yield"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %17 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
                    %18 = "eco.get_tag"(%17) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %19 = "arith.constant"() {value = 0 : i32} : () -> i32 
                    %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %31 = "eco.case"(%20) ({
                          %22 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
                          %24 = "eco.project.custom"(%22) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
                          %25 = "arith.constant"() {value = 0 : i64} : () -> i64 
                          %26 = "eco.int.eq"(%24, %25) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                          %29 = "eco.case"(%26) ({
                                %27 = "eco.string_literal"() {value = "b is zero"} : () -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.string_literal"() {value = "neither"} : () -> !eco.value 
                                "eco.yield"(%28) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%29) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %30 = "eco.string_literal"() {value = "neither"} : () -> !eco.value 
                          "eco.yield"(%30) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%31) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%32) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %34 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
              %35 = "eco.get_tag"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %36 = "arith.constant"() {value = 0 : i32} : () -> i32 
              %37 = "arith.cmpi"(%35, %36) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %48 = "eco.case"(%37) ({
                    %39 = "eco.project.tuple2"(%2) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
                    %41 = "eco.project.custom"(%39) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
                    %42 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    %43 = "eco.int.eq"(%41, %42) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                    %46 = "eco.case"(%43) ({
                          %44 = "eco.string_literal"() {value = "b is zero"} : () -> !eco.value 
                          "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %45 = "eco.string_literal"() {value = "neither"} : () -> !eco.value 
                          "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %47 = "eco.string_literal"() {value = "neither"} : () -> !eco.value 
                    "eco.yield"(%47) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%48) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%49) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Case2_classify_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %50 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%50) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Maybe_Nothing_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.call"(%arg0, %arg1) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Utils_append, eco.cse_safe}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Basics_append_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_eta114: !eco.value):
        %1 = "eco.call"(%_eta114) <{_operand_types = [!eco.value], callee = @VirtualDom_text_$_6}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Html_text_$_5", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.call"(%arg0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "VirtualDom_text_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Case2_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
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
  "eco.type_table"() {ctors = [[0, 0, 0, 1], [1, 2, 1, 0]], fields = [[1, 0], [0, 1], [0, 1]], func_args = [], strings = ["Just", "field0", "Nothing"], types = [[0, 0, 0], [1, 4, 0, 2], [2, 2, 2, 1, 2]]} : () -> () 
} 

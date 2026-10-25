module {
  "func.func"() ({
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %2 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %3 = "eco.construct.custom"(%2) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        %4 = "eco.construct.list"(%3, %1) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %5 = "eco.call"(%4) <{_operand_types = [!eco.value], callee = @Case_describe_$_2}> : (!eco.value) -> !eco.value 
        %6 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %7 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %8 = "eco.construct.custom"(%7) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        %9 = "eco.construct.list"(%8, %6) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %10 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %11 = "eco.construct.list"(%10, %9) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %12 = "eco.call"(%11) <{_operand_types = [!eco.value], callee = @Case_describe_$_2}> : (!eco.value) -> !eco.value 
        %13 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %14 = "eco.call"(%13) <{_operand_types = [!eco.value], callee = @Case_describe_$_2}> : (!eco.value) -> !eco.value 
        %15 = "eco.string.append"(%12, %14) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %0 = "eco.string.append"(%5, %15) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %17 = "eco.call"(%0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%17) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Case_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "Just", size = 1, slot_kinds = array<i8: 1>, tag = 0} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Maybe_Just_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value):
        %1 = "eco.get_tag"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %2 = "arith.constant"() {value = 65533 : i32} : () -> i32 
        %3 = "arith.cmpi"(%1, %2) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %34 = "eco.case"(%3) ({
              %4 = "eco.string_literal"() {value = "empty"} : () -> !eco.value 
              "eco.yield"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %5 = "eco.project.list_head"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %6 = "eco.get_tag"(%5) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %7 = "arith.constant"() {value = 0 : i32} : () -> i32 
              %8 = "arith.cmpi"(%6, %7) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %33 = "eco.case"(%8) ({
                    %9 = "eco.project.list_head"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %11 = "eco.project.custom"(%9) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
                    %12 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    %13 = "eco.int.eq"(%11, %12) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                    %27 = "eco.case"(%13) ({
                          %14 = "eco.string_literal"() {value = "starts with zero"} : () -> !eco.value 
                          "eco.yield"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %15 = "eco.project.list_tail"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %16 = "eco.get_tag"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %17 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %18 = "arith.cmpi"(%16, %17) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %26 = "eco.case"(%18) ({
                                %19 = "eco.project.list_head"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %21 = "eco.project.custom"(%19) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
                                %22 = "eco.string_literal"() {value = "one: "} : () -> !eco.value 
                                %23 = "eco.string.from_int"(%21) {_operand_types = [i64]} : (i64) -> !eco.value 
                                %24 = "eco.string.append"(%22, %23) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%24) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %25 = "eco.string_literal"() {value = "other"} : () -> !eco.value 
                                "eco.yield"(%25) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%26) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %28 = "eco.project.list_head"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %29 = "eco.project.list_tail"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %30 = "eco.string_literal"() {value = "skip "} : () -> !eco.value 
                    %31 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @Case_describe_$_2}> : (!eco.value) -> !eco.value 
                    %32 = "eco.string.append"(%30, %31) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%32) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%33) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:v:v"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Case_describe_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %35 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%35) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Maybe_Nothing_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Case_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 0, 0, 1], [1, 2, 1, 0]], fields = [[1, 0]], func_args = [], strings = ["Just", "field0", "Nothing"], types = [[0, 0, 0], [1, 4, 0, 2], [2, 1, 1]]} : () -> () 
} 

use syn::{visit::{self, Visit}, ItemFn, ExprMatch, ExprIf, ExprLoop, Block, Expr};
use std::cmp;
use super::CommonMetrics;

#[derive(Default)]
pub struct RustWalker {
    pub metrics: CommonMetrics,
    current_depth: usize,
}

impl<'ast> Visit<'ast> for RustWalker {
    fn visit_block(&mut self, i: &'ast Block) {
        self.current_depth += 1;
        self.metrics.max_nesting = cmp::max(self.metrics.max_nesting, self.current_depth);
        visit::visit_block(self, i);
        self.current_depth -= 1;
    }

    fn visit_expr_match(&mut self, i: &'ast ExprMatch) {
        self.metrics.logic_count += 1;
        visit::visit_expr_match(self, i);
    }
    fn visit_expr_if(&mut self, i: &'ast ExprIf) {
        self.metrics.logic_count += 1;
        visit::visit_expr_if(self, i);
    }

    fn visit_expr_loop(&mut self, i: &'ast ExprLoop) {
        self.metrics.logic_count += 1;
        visit::visit_expr_loop(self, i);
    }

    fn visit_expr(&mut self, i: &'ast Expr) {
        visit::visit_expr(self, i);
    }

    fn visit_item_fn(&mut self, i: &'ast ItemFn) {
        let old_depth = self.current_depth;
        self.current_depth = 0;
        visit::visit_item_fn(self, i);
        self.current_depth = old_depth;
    }
}

pub fn analyze_rust(content: &str, dict: &std::collections::HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
    let syntax = syn::parse_file(content)?;
    let mut walker = RustWalker::default();
    walker.metrics.loc = content.lines().count();
    walker.metrics.hotspot_lines = None;
    walker.metrics.hotspot_reason = None;
    walker.metrics.external_calls = 0;
    walker.metrics.internal_calls = 0;
    walker.visit_file(&syntax);
    
    // Dynamic Complexity from Config
    walker.metrics.complexity_penalty += super::apply_complexity_dictionary(content, dict);
    
    Ok(walker.metrics)
}

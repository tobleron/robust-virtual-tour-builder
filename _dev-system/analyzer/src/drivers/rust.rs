use super::CommonMetrics;
use quote::ToTokens;
use std::cmp;
use syn::{
    visit::{self, Visit},
    Block, Expr, ExprAssign, ExprIf, ExprLoop, ExprMatch, ItemFn, ItemMod, ItemUse, Pat, PatType,
};

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

    fn visit_item_use(&mut self, i: &'ast ItemUse) {
        // Extract basic path from use statements
        let dep = i.tree.to_token_stream().to_string().replace(" ", "");
        self.metrics.dependencies.push(dep);
        self.metrics.external_calls += 1;
        visit::visit_item_use(self, i);
    }

    fn visit_item_mod(&mut self, i: &'ast ItemMod) {
        // mod x; is a dependency on file x.rs/mod.rs.
        // mod x { ... } is NOT a file dependency (it's inline).
        if i.content.is_none() {
            let dep = i.ident.to_string();
            self.metrics.dependencies.push(dep);
            self.metrics.external_calls += 1;
        }
        visit::visit_item_mod(self, i);
    }

    fn visit_pat_type(&mut self, i: &'ast PatType) {
        if let Pat::Ident(ref id) = *i.pat {
            if id.mutability.is_some() {
                self.metrics.state_count += 1;
            }
        }
        visit::visit_pat_type(self, i);
    }

    fn visit_expr_assign(&mut self, i: &'ast ExprAssign) {
        self.metrics.state_count += 1;
        visit::visit_expr_assign(self, i);
    }
}

pub fn analyze_rust(
    content: &str,
    dict: &std::collections::HashMap<String, f64>,
) -> anyhow::Result<CommonMetrics> {
    let syntax = syn::parse_file(content)?;
    let mut walker = RustWalker::default();
    walker.metrics.loc = content.lines().count();
    walker.metrics.hotspot_lines = None;
    walker.metrics.hotspot_reason = None;
    walker.metrics.external_calls = 0;
    walker.metrics.internal_calls = 0;
    walker.metrics.state_count = 0;
    walker.metrics.dependencies = Vec::new();
    walker.visit_file(&syntax);

    // Dynamic Complexity from Config
    walker.metrics.complexity_penalty += super::apply_complexity_dictionary(content, dict);

    Ok(walker.metrics)
}

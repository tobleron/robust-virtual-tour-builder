import React from 'react';

/**
 * SafeErrorBoundaryInternal
 * Standard React Class Component for Error Boundary
 */
class SafeErrorBoundaryInternal extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true };
    }

    componentDidCatch(error, errorInfo) {
        if (this.props.onError) {
            try {
                this.props.onError(error, errorInfo);
            } catch (e) {
                console.error('Error in ErrorBoundary onError handler:', e);
            }
        }
    }

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) {
                return this.props.fallback;
            }

            // Default Premium-looking error UI
            return React.createElement(
                'div',
                {
                    style: {
                        position: 'fixed',
                        inset: 0,
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        backgroundColor: '#0f172a',
                        color: '#f8fafc',
                        padding: '2rem',
                        textAlign: 'center',
                        zIndex: 9999,
                        fontFamily: 'system-ui, -apple-system, sans-serif'
                    }
                },
                React.createElement(
                    'div',
                    {
                        style: {
                            maxWidth: '28rem',
                            padding: '2.5rem',
                            borderRadius: '1.5rem',
                            backgroundColor: 'rgba(30, 41, 59, 0.5)',
                            backdropFilter: 'blur(12px)',
                            border: '1px solid #334155',
                            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
                        }
                    },
                    [
                        React.createElement('h1', {
                            key: 'h1',
                            style: { fontSize: '1.875rem', fontWeight: 700, marginBottom: '0.75rem', letterSpacing: '-0.025em' }
                        }, 'Application Error'),
                        React.createElement('p', {
                            key: 'p',
                            style: { color: '#94a3b8', marginBottom: '2rem', lineHeight: 1.6 }
                        }, 'An unexpected error occurred during rendering. The application has been halted to prevent data corruption.'),
                        React.createElement('button', {
                            key: 'btn',
                            onClick: () => window.location.reload(),
                            style: {
                                width: '100%',
                                backgroundColor: '#2563eb',
                                color: 'white',
                                fontWeight: 600,
                                padding: '0.875rem 1.5rem',
                                borderRadius: '0.75rem',
                                border: 'none',
                                cursor: 'pointer',
                                transition: 'background-color 0.2s'
                            },
                            onMouseOver: (e) => e.target.style.backgroundColor = '#3b82f6',
                            onMouseOut: (e) => e.target.style.backgroundColor = '#2563eb'
                        }, 'Reload Application')
                    ]
                )
            );
        }

        return this.props.children;
    }
}

// Export the class directly. React.createElement(SafeErrorBoundaryComponent, props) works for classes.
export const SafeErrorBoundaryComponent = SafeErrorBoundaryInternal;

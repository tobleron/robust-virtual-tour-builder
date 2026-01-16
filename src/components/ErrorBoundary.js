import React from 'react';

class ErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        if (this.props.onError) {
            this.props.onError(error, errorInfo);
        }
    }

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) {
                return this.props.fallback;
            }
            return React.createElement(
                'div',
                { className: 'fixed inset-0 flex flex-col items-center justify-center bg-slate-900 text-slate-50 p-8 text-center z-[9999]' },
                React.createElement(
                    'div',
                    { className: 'max-w-md p-8 rounded-2xl bg-slate-800/50 backdrop-blur-md border border-slate-700 shadow-2xl animate-fade-in' },
                    React.createElement(
                        'div',
                        { className: 'w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mb-6 mx-auto' },
                        React.createElement(
                            'svg',
                            {
                                xmlns: 'http://www.w3.org/2000/svg',
                                className: 'w-8 h-8 text-red-500',
                                fill: 'none',
                                viewBox: '0 0 24 24',
                                stroke: 'currentColor'
                            },
                            React.createElement('path', {
                                strokeLinecap: 'round',
                                strokeLinejoin: 'round',
                                strokeWidth: 2,
                                d: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z'
                            })
                        )
                    ),
                    React.createElement('h1', { className: 'text-3xl font-bold mb-3 tracking-tight' }, 'Application Error'),
                    React.createElement(
                        'p',
                        { className: 'text-slate-400 mb-8 leading-relaxed' },
                        'An unexpected error occurred in the viewer rendering engine. Our telemetry system has recorded this event.'
                    ),
                    React.createElement(
                        'button',
                        {
                            onClick: () => window.location.reload(),
                            className: 'w-full bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold py-3 px-6 rounded-xl transition-all duration-200 shadow-lg shadow-blue-600/20 active:scale-95'
                        },
                        'Restart Application'
                    )
                )
            );
        }

        return this.props.children;
    }
}

export default ErrorBoundary;

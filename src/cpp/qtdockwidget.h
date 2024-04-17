#include <QtWidgets>

class ZigQt : public QObject {
    Q_OBJECT

    public:
	void ZigQT() {}
	~ZigQt() {}
        QDockWidget* createDock(QWidget *parent = nullptr);

};


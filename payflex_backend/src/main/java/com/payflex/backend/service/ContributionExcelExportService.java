package com.payflex.backend.service;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * Export .xlsx de la liste des cotisations (Apache POI), même esprit que les exports CSV/PDF déjà
 * en place dans {@code AdminExportController} (non modifié ici pour éviter toute collision — voir
 * limites connues dans la synthèse finale de la tâche 4).
 */
@Service
public class ContributionExcelExportService {

    public byte[] exportContributions(List<AdminCrudService.ContributionRow> rows) throws IOException {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            XSSFSheet sheet = workbook.createSheet("Cotisations");

            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);

            String[] headers = {
                "ID", "Client", "Produit", "Agent", "Montant (FCFA)", "Mode de paiement", "Statut", "Référence"
            };
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (AdminCrudService.ContributionRow r : rows) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(r.id());
                row.createCell(1).setCellValue(nullToDash(r.userName()));
                row.createCell(2).setCellValue(nullToDash(r.productName()));
                row.createCell(3).setCellValue(nullToDash(r.agentName()));
                row.createCell(4).setCellValue(r.amount());
                row.createCell(5).setCellValue(AdminAuditService.modePaiement(r.paymentMode()));
                row.createCell(6).setCellValue(AdminAuditService.statutCotisation(r.status()));
                row.createCell(7).setCellValue(nullToDash(r.referenceCode()));
            }

            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);
            return out.toByteArray();
        }
    }

    private static String nullToDash(String v) {
        return v == null || v.isBlank() ? "—" : v;
    }
}
